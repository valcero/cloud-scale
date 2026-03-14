import json
import base64
import boto3
import logging
from datetime import datetime
from uuid import uuid4

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
DATA_LAKE_BUCKET = 'cloudscale-data-lake-production'


def lambda_handler(event, context):
    """Process Kinesis events and write to S3 data lake in partitioned format."""
    output_records = []
    success_count = 0
    failure_count = 0

    for record in event['Records']:
        try:
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            data = json.loads(payload)

            enriched = enrich_event(data)

            s3_key = generate_s3_key(enriched)
            s3_client.put_object(
                Bucket=DATA_LAKE_BUCKET,
                Key=s3_key,
                Body=json.dumps(enriched),
                ContentType='application/json',
            )

            success_count += 1
            output_records.append({
                'recordId': record['eventID'],
                'result': 'Ok',
            })
        except Exception as e:
            failure_count += 1
            logger.error(f"Failed to process record: {str(e)}")
            output_records.append({
                'recordId': record.get('eventID', 'unknown'),
                'result': 'ProcessingFailed',
            })

    logger.info(f"Processed {success_count} records, {failure_count} failures")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': success_count,
            'failed': failure_count,
        }),
    }


def enrich_event(data):
    """Add processing metadata to the event."""
    now = datetime.utcnow()
    return {
        **data,
        'processed_at': now.isoformat(),
        'processing_id': str(uuid4()),
        'year': now.strftime('%Y'),
        'month': now.strftime('%m'),
        'day': now.strftime('%d'),
        'hour': now.strftime('%H'),
    }


def generate_s3_key(data):
    """Generate a partitioned S3 key for efficient querying."""
    event_type = data.get('event_type', 'unknown')
    year = data['year']
    month = data['month']
    day = data['day']
    hour = data['hour']
    processing_id = data['processing_id']

    return (
        f"events/event_type={event_type}/"
        f"year={year}/month={month}/day={day}/hour={hour}/"
        f"{processing_id}.json"
    )
