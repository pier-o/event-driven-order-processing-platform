from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/api/auth/health")
def health():
    return jsonify({
        "service": "auth",
        "status": "ok"
    })


@app.get("/api/auth")
def auth():
    return jsonify({
        "service": "auth",
        "message": "Auth service v2 is running"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)