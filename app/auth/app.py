import hashlib
import json
import os
import secrets
import uuid

import boto3
import psycopg
import redis
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError
from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request
from psycopg.errors import UniqueViolation

app = Flask(__name__)

# AWS clients
secrets_manager = boto3.client("secretsmanager")

# Database configuration
DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_SECRET_ARN = os.environ["DB_SECRET_ARN"]

# Redis configuration
REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

# Session configuration
SESSION_TTL_SECONDS = 900

_db_credentials = None

# Redis client
redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    ssl=True,
    decode_responses=True
)

# Password hasher
password_hasher = PasswordHasher()


def get_db_credentials():
    global _db_credentials

    if _db_credentials is None:
        response = secrets_manager.get_secret_value(
            SecretId=DB_SECRET_ARN
        )

        secret = json.loads(response["SecretString"])

        _db_credentials = {
            "username": secret["username"],
            "password": secret["password"]
        }

    return _db_credentials


def get_db_connection():
    credentials = get_db_credentials()

    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=credentials["username"],
        password=credentials["password"],
        sslmode="require"
    )


def init_db():
    with get_db_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                user_id UUID PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
            """
        )
        conn.commit()


def hash_password(password):
    return password_hasher.hash(password)


def verify_password(password, password_hash):
    try:
        password_hasher.verify(password_hash, password)
        return True
    except (VerifyMismatchError, VerificationError):
        return False


def generate_session_token():
    return secrets.token_urlsafe(32)


def session_key(token):
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    return f"session:{token_hash}"


def get_bearer_token():
    authorization = request.headers.get("Authorization", "")

    scheme, _, token = authorization.partition(" ")

    if scheme.lower() != "bearer" or not token:
        return None

    return token


def get_authenticated_user_id():
    token = get_bearer_token()

    if token is None:
        return None

    user_id = redis_client.get(session_key(token))

    if user_id is None:
        return None

    return user_id


@app.get("/api/auth/health")
def health():
    return jsonify({
        "service": "auth",
        "status": "ok"
    })


@app.get("/api/auth/dependencies")
def dependencies():
    result = {
        "postgresql": "unknown",
        "redis": "unknown"
    }

    try:
        with get_db_connection() as conn:
            conn.execute("SELECT 1")

        result["postgresql"] = "ok"

    except (BotoCoreError, ClientError, psycopg.Error) as exc:
        app.logger.error(
            "PostgreSQL connection failed: %s",
            exc
        )
        result["postgresql"] = "failed"

    try:
        redis_client.ping()
        result["redis"] = "ok"

    except redis.RedisError as exc:
        app.logger.error(
            "Redis connection failed: %s",
            exc
        )
        result["redis"] = "failed"

    status_code = 200 if all(
        value == "ok"
        for value in result.values()
    ) else 500

    return jsonify(result), status_code


@app.post("/api/auth/register")
def register():
    data = request.get_json(silent=True) or {}

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email:
        return jsonify({
            "error": "email is required"
        }), 400

    if not password:
        return jsonify({
            "error": "password is required"
        }), 400

    password_hash = hash_password(password)
    user_id = uuid.uuid4()

    try:
        with get_db_connection() as conn:
            conn.execute(
                """
                INSERT INTO users (
                    user_id,
                    email,
                    password_hash
                )
                VALUES (%s, %s, %s)
                """,
                (
                    user_id,
                    email,
                    password_hash
                )
            )
            conn.commit()

    except UniqueViolation:
        return jsonify({
            "error": "Email already registered"
        }), 409

    except (BotoCoreError, ClientError, psycopg.Error) as exc:
        app.logger.error(
            "Failed to register user: %s",
            exc
        )
        return jsonify({
            "error": "Failed to register user"
        }), 500

    return jsonify({
        "message": "User registered",
        "user_id": str(user_id),
        "email": email
    }), 201


@app.post("/api/auth/login")
def login():
    data = request.get_json(silent=True) or {}

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({
            "error": "email and password are required"
        }), 400

    try:
        with get_db_connection() as conn:
            row = conn.execute(
                """
                SELECT user_id, password_hash
                FROM users
                WHERE email = %s
                """,
                (email,)
            ).fetchone()

    except (BotoCoreError, ClientError, psycopg.Error) as exc:
        app.logger.error(
            "Failed to look up user: %s",
            exc
        )
        return jsonify({
            "error": "Login failed"
        }), 500

    if row is None:
        return jsonify({
            "error": "Invalid email or password"
        }), 401

    user_id, password_hash = row

    if not verify_password(password, password_hash):
        return jsonify({
            "error": "Invalid email or password"
        }), 401

    token = generate_session_token()

    try:
        redis_client.setex(
            session_key(token),
            SESSION_TTL_SECONDS,
            str(user_id)
        )

    except redis.RedisError as exc:
        app.logger.error(
            "Failed to create session: %s",
            exc
        )
        return jsonify({
            "error": "Login failed (session creation)"
        }), 500

    return jsonify({
        "message": "Login successful",
        "token": token,
        "expires_in": SESSION_TTL_SECONDS
    }), 200


@app.get("/api/auth/me")
def me():
    user_id = get_authenticated_user_id()

    if user_id is None:
        return jsonify({
            "error": "Unauthorized"
        }), 401

    return jsonify({
        "authenticated": True,
        "user_id": user_id
    }), 200


@app.post("/api/auth/logout")
def logout():
    token = get_bearer_token()

    if token is None:
        return jsonify({
            "error": "Authorization token is required"
        }), 401

    try:
        redis_client.delete(session_key(token))

    except redis.RedisError as exc:
        app.logger.error(
            "Failed to delete session: %s",
            exc
        )
        return jsonify({
            "error": "Logout failed"
        }), 500

    return jsonify({
        "message": "Logged out"
    }), 200


@app.get("/api/auth")
def auth():
    return jsonify({
        "service": "auth",
        "message": "Auth service v6 is running"
    })


init_db()


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=80
    )