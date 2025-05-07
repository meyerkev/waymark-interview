import json
import boto3
import logging
from datetime import timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

def handler(event, context):
    for record in event.get("Records", []):
        s3_info = record.get("s3", {})
        bucket = s3_info.get("bucket", {}).get("name")
        key = s3_info.get("object", {}).get("key")

        if not bucket or not key:
            logger.warning("Missing bucket or key in event record: %s", record)
            continue

        try:
            logger.info(f"Reading {bucket}/{key}")
            head = s3.head_object(Bucket=bucket, Key=key)
            last_modified = head["LastModified"].astimezone(timezone.utc).isoformat()

            # We're doing something with metadata, so let's do something with metadata
            logger.info(
                json.dumps({
                    "event": "file_uploaded",
                    "bucket": bucket,
                    "key": key,
                    "uploaded_at": last_modified,
                    "size_bytes": head["ContentLength"],
                    "content_type": head.get("ContentType", "unknown"),
                    "metadata": head.get("Metadata", {}),
                })
            )

        except Exception as e:
            logger.exception(f"Failed to process object {bucket}/{key}: {e}")
            raise e
