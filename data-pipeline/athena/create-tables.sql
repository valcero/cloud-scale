-- CloudScale Athena Table Definitions
-- These queries create external tables over the S3 data lake

CREATE EXTERNAL TABLE IF NOT EXISTS cloudscale_events (
  id STRING,
  event_type STRING,
  source STRING,
  user_id INT,
  payload STRING,
  created_at TIMESTAMP,
  processed_at TIMESTAMP,
  processing_id STRING
)
PARTITIONED BY (
  year STRING,
  month STRING,
  day STRING,
  hour STRING
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('ignore.malformed.json' = 'true')
LOCATION 's3://cloudscale-data-lake-production/events/'
TBLPROPERTIES ('has_encrypted_data' = 'true');

-- Repair partitions after data loads
MSCK REPAIR TABLE cloudscale_events;
