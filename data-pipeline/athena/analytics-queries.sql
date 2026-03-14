-- CloudScale Analytics Queries for Athena

-- Daily event counts by type
SELECT
  event_type,
  year,
  month,
  day,
  COUNT(*) as event_count
FROM cloudscale_events
WHERE year = '2024'
GROUP BY event_type, year, month, day
ORDER BY year, month, day, event_count DESC;

-- Hourly traffic pattern
SELECT
  hour,
  COUNT(*) as events,
  COUNT(DISTINCT user_id) as unique_users
FROM cloudscale_events
WHERE year = '2024' AND month = '01'
GROUP BY hour
ORDER BY hour;

-- Top event sources
SELECT
  source,
  event_type,
  COUNT(*) as total_events,
  COUNT(DISTINCT user_id) as unique_users
FROM cloudscale_events
WHERE year || '-' || month || '-' || day >= '2024-01-01'
GROUP BY source, event_type
ORDER BY total_events DESC
LIMIT 20;

-- User activity summary
SELECT
  user_id,
  COUNT(*) as total_events,
  COUNT(DISTINCT event_type) as event_types,
  MIN(created_at) as first_activity,
  MAX(created_at) as last_activity
FROM cloudscale_events
WHERE user_id IS NOT NULL
GROUP BY user_id
ORDER BY total_events DESC
LIMIT 100;

-- Error events analysis
SELECT
  source,
  event_type,
  year,
  month,
  day,
  COUNT(*) as error_count
FROM cloudscale_events
WHERE event_type LIKE '%error%' OR event_type LIKE '%fail%'
GROUP BY source, event_type, year, month, day
ORDER BY error_count DESC;

-- Funnel analysis: user registration → order → payment
WITH user_events AS (
  SELECT
    user_id,
    event_type,
    MIN(created_at) as first_occurrence
  FROM cloudscale_events
  WHERE user_id IS NOT NULL
    AND event_type IN ('user_registered', 'order_created', 'payment_completed')
  GROUP BY user_id, event_type
)
SELECT
  COUNT(DISTINCT CASE WHEN event_type = 'user_registered' THEN user_id END) as registered,
  COUNT(DISTINCT CASE WHEN event_type = 'order_created' THEN user_id END) as ordered,
  COUNT(DISTINCT CASE WHEN event_type = 'payment_completed' THEN user_id END) as paid
FROM user_events;
