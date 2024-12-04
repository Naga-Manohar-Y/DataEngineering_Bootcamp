


DROP TABLE user_devices_cumulated;

CREATE TABLE user_devices_cumulated(
user_id TEXT,
browser_type TEXT,
dates_active DATE[],
date DATE,
PRIMARY KEY (user_id, browser_type, date)
);
---------------------------------------------------------------------------
WITH yesterday AS (
SELECT * 
FROM user_devices_cumulated
WHERE date = DATE('2023-01-04')
),
dedupe AS (
	SELECT CAST(e.user_id AS TEXT) AS user_id, 
	DATE(CAST(e.event_time AS TIMESTAMP)) AS date_active,
	d.browser_type AS browser_type,
	ROW_NUMBER () OVER 
	(PARTITION BY e.user_id, DATE(CAST(e.event_time AS TIMESTAMP)), d.browser_type
	ORDER BY e.event_time) AS row_num
	FROM events e INNER JOIN devices d
	ON e.device_id = d.device_id
	WHERE DATE(CAST(event_time AS TIMESTAMP)) = DATE('2023-01-05') 
	AND e.user_id IS NOT NULL
	),
today AS (
	SELECT user_id, date_active, browser_type
	FROM dedupe
	WHERE row_num = 1

)
SELECT 
	COALESCE(t.user_id, y.user_id) AS user_id,
	COALESCE(t.browser_type, y.browser_type) AS browser_type,
	CASE
		WHEN y.dates_active IS NULL THEN ARRAY[t.date_active]
		WHEN t.date_active IS NULL THEN y.dates_active
		ELSE ARRAY[t.date_active] || y.dates_active
		END AS dates_active,
	COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date
	
	FROM today t FULL OUTER JOIN yesterday y
	ON t.user_id = y.user_id AND t.browser_type = y.browser_type;

--------------------------------------------------------------------------
DO $$
DECLARE
	current_loop_date DATE:= '2023-01-01';
	end_date DATE:= '2023-01-31';
BEGIN
	WHILE current_loop_date <= end_date LOOP
		INSERT INTO user_devices_cumulated
		WITH yesterday AS (
			SELECT * 
			FROM user_devices_cumulated
			WHERE date = current_loop_date - INTERVAL '1 day'
		),
			dedupe AS (
			SELECT CAST(e.user_id AS TEXT) AS user_id, 
				DATE(CAST(e.event_time AS TIMESTAMP)) AS date_active,
				d.browser_type AS browser_type,
				ROW_NUMBER () OVER 
				(PARTITION BY e.user_id, DATE(CAST(e.event_time AS TIMESTAMP)), d.browser_type
			ORDER BY e.event_time) AS row_num
			FROM events e INNER JOIN devices d
			ON e.device_id = d.device_id
			WHERE DATE(CAST(event_time AS TIMESTAMP)) = current_loop_date 
			AND e.user_id IS NOT NULL
		),
		today AS (
			SELECT user_id, date_active, browser_type
			FROM dedupe
			WHERE row_num = 1

		)
	SELECT 
		COALESCE(t.user_id, y.user_id) AS user_id,
		COALESCE(t.browser_type, y.browser_type) AS browser_type,
		CASE
			WHEN y.dates_active IS NULL THEN ARRAY[t.date_active]
			WHEN t.date_active IS NULL THEN y.dates_active
			ELSE ARRAY[t.date_active] || y.dates_active
			END AS dates_active,
		COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date
		FROM today t FULL OUTER JOIN yesterday y
		ON t.user_id = y.user_id AND t.browser_type = y.browser_type;
		current_loop_date := current_loop_date + INTERVAL '1 day';
	END LOOP;
END $$;		
---------------------------------------------
SELECT * FROM user_devices_cumulated
ORDER BY 1,2;
------------------------------------------------------------
-- SELECT *, COUNT(*) FROM test
-- GROUP BY user_id,  browser_type, dates_active, date;
------------------------------------------------------------

WITH users AS (
	SELECT * FROM user_devices_cumulated
	WHERE date = DATE('2023-01-31')
),
	series AS (
		SELECT * FROM generate_series(DATE('2023-01-01'), DATE('2023-01-31'), INTERVAL '1 day') 
		AS series_date
	),
	place_holder_ints AS (
		SELECT 
		CASE WHEN 
			dates_active @> ARRAY [DATE(series_date)]
		THEN POW(2,31 - (date - DATE(series_date)))
		ELSE 0
		END AS placeholder_int_value, *
		FROM users CROSS JOIN series
	)
SELECT 
	user_id,
	browser_type,
	CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32)) AS datelist_int
FROM place_holder_ints
GROUP BY user_id, browser_type;

--------------------------------------------------------------------------------

SELECT * FROM events limit 5;
--------------
DROP TABLE host_cummulated;
CREATE TABLE host_cummulated (
host TEXT,
host_activity_datelist DATE[],
date DATE,
PRIMARY KEY (host, host_activity_datelist, date)
);
-----------------------------Incremental query host
DO $$
DECLARE
	current_loop_date DATE:= '2023-01-01';
	end_date DATE:= '2023-01-31';
BEGIN
	WHILE current_loop_date <= end_date LOOP
		INSERT INTO host_cummulated
		WITH yesterday AS (
		SELECT *
		FROM host_cummulated
		WHERE date = current_loop_date - INTERVAL '1 Day'
		),
		dedupe AS (
		SELECT CAST(host AS TEXT) AS host, 
			DATE(CAST(event_time AS TIMESTAMP)) AS date_active,
			ROW_NUMBER () OVER 
			(PARTITION BY host, DATE(CAST(event_time AS TIMESTAMP))
			ORDER BY event_time) AS row_num
		FROM events
		WHERE DATE(CAST(event_time AS TIMESTAMP)) = current_loop_date
	),
	today AS (
	SELECT host, date_active
	FROM dedupe WHERE row_num = 1
	)

	SELECT COALESCE(t.host, y.host) AS host,
	CASE
		WHEN y.host_activity_datelist IS NULL THEN ARRAY[t.date_active]
		WHEN t.date_active IS NULL THEN y.host_activity_datelist
		ELSE ARRAY[t.date_active] || y.host_activity_datelist
		END AS host_activity_datelist,
	COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date
	FROM today t FULL OUTER JOIN yesterday y
	ON t.host = y.host;
	current_loop_date := current_loop_date + INTERVAL '1 day';
	END LOOP;
END $$;	
------------------
select * from host_cummulated
order by date desc;
---------------------- DDL
DROP TABLE host_activity_reduced

CREATE TABLE host_activity_reduced(
host TEXT,
month_start DATE,
hit_array REAL [],
unique_visitors REAL [],
PRIMARY KEY (host, month_start, hit_array)
);
-------------------
DO $$
DECLARE
	current_loop_date DATE:= '2023-01-01';
	end_date DATE:= '2023-01-31';
BEGIN
	WHILE current_loop_date <= end_date LOOP
		INSERT INTO host_activity_reduced
		WITH daily_aggregates AS (
		SELECT host, DATE(CAST(event_time AS TIMESTAMP)) AS date, 
			COUNT(user_id) AS num_site_hits,
			COUNT(DISTINCT user_id) AS unique_visitors
		FROM events
		WHERE DATE(event_time) = current_loop_date 
		AND user_id IS NOT NULL 
		GROUP BY host, DATE(CAST(event_time AS TIMESTAMP))
		),
		yesterday_array AS (
			SELECT *
			FROM host_activity_reduced
			WHERE month_start = current_loop_date - INTERVAL '1 Day'
		)
		SELECT 
			COALESCE(da.host, ya.host) as host,
			COALESCE(da.date, ya.month_start) AS month_start,
			CASE 
				WHEN ya.hit_array IS NOT NULL 
				THEN ya.hit_array || ARRAY[COALESCE(da.num_site_hits, 0)]
				WHEN ya.hit_array IS NULL 
				THEN ARRAY_FILL(0, ARRAY[COALESCE(date - DATE(DATE_TRUNC('month',date)),0)]) 
				|| ARRAY[COALESCE(da.num_site_hits, 0)]
			END AS hit_array,
			CASE 
				WHEN ya.unique_visitors IS NOT NULL 
				THEN ya.unique_visitors || ARRAY[COALESCE(da.unique_visitors, 0)]
				WHEN ya.unique_visitors IS NULL 
				THEN ARRAY_FILL(0, ARRAY[COALESCE(date - DATE(DATE_TRUNC('month',date)),0)]) 
				|| ARRAY[COALESCE(da.unique_visitors, 0)]
			END AS unique_visitors
		FROM daily_aggregates da FULL OUTER JOIN yesterday_array ya 
		ON da.host = ya.host
		
		ON CONFLICT (host, month_start, hit_array)
		DO
			UPDATE SET hit_array = EXCLUDED.hit_array,
			unique_visitors = EXCLUDED.unique_visitors;
		current_loop_date := current_loop_date + INTERVAL '1 Day';
	END LOOP;
END $$;
-----------------------------------------
-- INSERT INTO host_activity_reduced
-- 		WITH daily_aggregates AS (
-- 		SELECT host, DATE(CAST(event_time AS TIMESTAMP)) AS date, 
-- 			COUNT(user_id) AS num_site_hits,
-- 			COUNT(DISTINCT user_id) AS unique_visitors
-- 		FROM events
-- 		WHERE DATE(event_time) =  DATE('2023-01-03')
-- 		AND user_id IS NOT NULL 
-- 		GROUP BY host, DATE(CAST(event_time AS TIMESTAMP))
-- 		),
-- 		yesterday_array AS (
-- 			SELECT *
-- 			FROM host_activity_reduced
-- 			WHERE month_start = DATE('2023-01-02')
-- 		)
-- 		SELECT 
-- 			COALESCE(da.host, ya.host) as host,
-- 			COALESCE(da.date, ya.month_start) AS month_start,
-- 			CASE 
-- 				WHEN ya.hit_array IS NOT NULL 
-- 				THEN ya.hit_array || ARRAY[COALESCE(da.num_site_hits, 0)]
-- 				WHEN ya.hit_array IS NULL 
-- 				THEN ARRAY_FILL(0, ARRAY[COALESCE(date - DATE(DATE_TRUNC('month',date)),0)]) 
-- 				|| ARRAY[COALESCE(da.num_site_hits, 0)]
-- 			END AS hit_array,
-- 			CASE 
-- 				WHEN ya.unique_visitors IS NOT NULL 
-- 				THEN ya.unique_visitors || ARRAY[COALESCE(da.unique_visitors, 0)]
-- 				WHEN ya.unique_visitors IS NULL 
-- 				THEN ARRAY_FILL(0, ARRAY[COALESCE(date - DATE(DATE_TRUNC('month',date)),0)]) 
-- 				|| ARRAY[COALESCE(da.unique_visitors, 0)]
-- 			END AS unique_visitors
-- 		FROM daily_aggregates da FULL OUTER JOIN yesterday_array ya 
-- 		ON da.host = ya.host;

		
SELECT * FROM host_activity_reduced;
