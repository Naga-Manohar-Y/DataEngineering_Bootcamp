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
