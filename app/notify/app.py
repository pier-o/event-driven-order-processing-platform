import json
import os
import threading

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify

app = Flask(__name__)

sqs = boto3.client("sqs")
sns = boto3.client("sns")

SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def process_messages():
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20
            )

            messages = response.get("Messages", [])

            for message in messages:
                try:
                    event = json.loads(message["Body"])
                    detail = event.get("detail", {})

                    notification = {
                        "type": "OrderNotification",
                        "order": detail
                    }

                    sns.publish(
                        TopicArn=SNS_TOPIC_ARN,
                        Message=json.dumps(notification)
                    )

                    sqs.delete_message(
                        QueueUrl=SQS_QUEUE_URL,
                        ReceiptHandle=message["ReceiptHandle"]
                    )

                    app.logger.info(
                        "Processed OrderCreated event for order_id=%s",
                        detail.get("order_id")
                    )

                except Exception as exc:
                    app.logger.error(
                        "Failed to process SQS message: %s",
                        exc
                    )

        except (BotoCoreError, ClientError) as exc:
            app.logger.error(
                "SQS polling error: %s",
                exc
            )


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
        "message": "Notification service is running"
    })


worker = threading.Thread(
    target=process_messages,
    daemon=True
)

worker.start()