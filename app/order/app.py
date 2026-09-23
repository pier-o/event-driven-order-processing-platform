from flask import Flask, jsonify

app = Flask(__name__)


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
        "message": "Order service v2 is running"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)