import json
import os
import uuid

import boto3
import psycopg

from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request
from psycopg.types.json import Jsonb

app = Flask(__name__)

eventbridge = boto3.client("events")
secrets_manager = boto3.client("secretsmanager")

EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_SECRET_ARN = os.environ["DB_SECRET_ARN"]

_db_credentials = None

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
            CREATE TABLE IF NOT EXISTS orders (
                order_id UUID PRIMARY KEY,
                customer_id TEXT NOT NULL,
                items JSONB NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
            """
        )

        conn.commit()


@app.get("/api/order/health")
def health():
    return jsonify({
        "service": "order",
        "status": "ok"
    })


@app.get("/api/order")
def order():
    return jsonify({
        "service": "order",
        "message": "Order service is running"
    })


@app.get("/api/order/<order_id>")
def get_order(order_id):
    try:
        with get_db_connection() as conn:
            row = conn.execute(
                """
                SELECT order_id, customer_id, items, created_at
                FROM orders
                WHERE order_id = %s
                """,
                (order_id,)
            ).fetchone()

        if row is None:
            return jsonify({
                "error": "Order not found"
            }), 404

        return jsonify({
            "order_id": str(row[0]),
            "customer_id": row[1],
            "items": row[2],
            "created_at": row[3].isoformat()
        })

    except (BotoCoreError, ClientError, psycopg.Error) as exc:
        app.logger.error(
            "Failed to retrieve order: %s",
            exc
        )

        return jsonify({
            "error": "Failed to retrieve order"
        }), 500


@app.post("/api/order")
def create_order():
    data = request.get_json(silent=True) or {}

    customer_id = data.get("customer_id")
    items = data.get("items", [])

    if not customer_id:
        return jsonify({
            "error": "customer_id is required"
        }), 400

    order = {
        "order_id": str(uuid.uuid4()),
        "customer_id": customer_id,
        "items": items
    }

    try:
        # 1. Persist the order first.
        with get_db_connection() as conn:
            conn.execute(
                """
                INSERT INTO orders (
                    order_id,
                    customer_id,
                    items
                )
                VALUES (%s, %s, %s)
                """,
                (
                    order["order_id"],
                    order["customer_id"],
                    Jsonb(order["items"])
                )
            )

            conn.commit()

        app.logger.info(
            "Order stored in PostgreSQL: order_id=%s",
            order["order_id"]
        )

        # 2. Publish the event only after the DB write succeeds.
        response = eventbridge.put_events(
            Entries=[
                {
                    "Source": "order-service",
                    "DetailType": "OrderCreated",
                    "Detail": json.dumps(order),
                    "EventBusName": EVENT_BUS_NAME
                }
            ]
        )

        if response.get("FailedEntryCount", 0) > 0:
            app.logger.error(
                "Failed to publish OrderCreated event: %s",
                response
            )

            return jsonify({
                "error": "Order was stored but event publishing failed",
                "order": order
            }), 500

        app.logger.info(
            "OrderCreated event published: order_id=%s",
            order["order_id"]
        )

    except (BotoCoreError, ClientError, psycopg.Error) as exc:
        app.logger.error(
            "Failed to create order: %s",
            exc
        )

        return jsonify({
            "error": "Failed to create order"
        }), 500

    return jsonify({
        "message": "Order created",
        "order": order
    }), 201


init_db()