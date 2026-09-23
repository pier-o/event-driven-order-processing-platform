from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/api/notify/health")
def health():
    return jsonify({
        "service": "notify",
        "status": "ok"
    })


@app.get("/api/notify")
def notify():
    return jsonify({
        "service": "notify",
        "message": "Notification service v2 is running"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)