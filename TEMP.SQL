-- Building Slowly Changing Dimensions

select * from player_seasons limit 5;

create type season_stats as (
season integer,
gp integer,
pts real,
reb real,
ast real
);

drop table players;

create type scoring_class as enum ('star', 'good', 'average', 'bad');
--------------------Table creation ----------------------------------
create table players(
player_name text,
height text,
college text,
country text,
draft_year text,
draft_round text,
draft_number text,
season_stats season_stats[],
scoring_class scoring_class,
years_since_last_season integer,
current_season integer,
is_active boolean,
primary key(player_name, current_season)
);

select * from players order by 1, 11 limit 20;
-----------------------------Inserting the data ----------------------
INSERT INTO players
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1996, 2022) AS season
), p AS (
    SELECT
        player_name,
        MIN(season) AS first_season
    FROM player_seasons
    GROUP BY player_name
), players_and_seasons AS (
    SELECT *
    FROM p
    JOIN years y
        ON p.first_season <= y.season
), windowed AS (
    SELECT
        pas.player_name,
        pas.season,
        ARRAY_REMOVE(
            ARRAY_AGG(
                CASE
                    WHEN ps.season IS NOT NULL
                        THEN ROW(
                            ps.season,
                            ps.gp,
                            ps.pts,
                            ps.reb,
                            ps.ast
                        )::season_stats
                END)
            OVER (PARTITION BY pas.player_name ORDER BY COALESCE(pas.season, ps.season)),
            NULL
        ) AS seasons
    FROM players_and_seasons pas
    LEFT JOIN player_seasons ps
        ON pas.player_name = ps.player_name
        AND pas.season = ps.season
    ORDER BY pas.player_name, pas.season
), static AS (
    SELECT
        player_name,
        MAX(height) AS height,
        MAX(college) AS college,
        MAX(country) AS country,
        MAX(draft_year) AS draft_year,
        MAX(draft_round) AS draft_round,
        MAX(draft_number) AS draft_number
    FROM player_seasons
    GROUP BY player_name
)
SELECT
    w.player_name,
    s.height,
    s.college,
    s.country,
    s.draft_year,
    s.draft_round,
    s.draft_number,
    seasons AS season_stats,
    CASE
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 20 THEN 'star'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 15 THEN 'good'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 10 THEN 'average'
        ELSE 'bad'
    END::scoring_class AS scoring_class,
    w.season - (seasons[CARDINALITY(seasons)]::season_stats).season as years_since_last_active,
    w.season,
    (seasons[CARDINALITY(seasons)]::season_stats).season = season AS is_active
FROM windowed w
JOIN static s
    ON w.player_name = s.player_name;

----------------------------Creating SCD table------------------------
DROP TABLE players_scd;
CREATE TABLE players_scd (
player_name TEXT,
scoring_class scoring_class,
is_active BOOLEAN,
current_season INTEGER,
start_season INTEGER,
end_season INTEGER,
PRIMARY KEY(player_name, start_season)
);

--------------------------- creating scd data and loading it into table ------------

INSERT INTO players_scd
WITH with_previous as (
SELECT
player_name,
current_season,
scoring_class,
is_active,
LAG(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) as previous_scoring_class,
LAG(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) as previous_is_active
FROM players
WHERE current_season <= 2021
),
with_indicators AS(
SELECT *,
CASE
WHEN scoring_class <> previous_scoring_class THEN 1
WHEN is_active <> previous_is_active THEN 1
END AS change_indicator
FROM with_previous
),
with_streaks AS (
 SELECT *,
SUM(change_indicator) OVER (PARTITION BY player_name ORDER BY current_season) AS streak_identifier
FROM with_indicators
)

SELECT player_name,
scoring_class,
is_active,
2021 AS current_season,
MIN(current_season) as start_season,
MAX(current_season) as end_season
FROM with_streaks
GROUP BY player_name, streak_identifier, is_active, scoring_class
ORDER BY player_name, streak_identifier;

-------------------------------------------------------------------
select * from players_scd order by 1,5 limit 20;


SELECT current_season, end_season FROM players_scd
where current_season = 2021;
-------------------------------------------------------------------

-------------------------------------------------------------------
-- HW 5
DROP TABLE players_state_change;

CREATE TABLE players_state_change(
player_name TEXT,
first_active_season INTEGER,
last_active_season INTEGER,
current_season INTEGER,
state_change TEXT,
PRIMARY KEY (player_name, current_season)
);

INSERT INTO players_state_change
WITH last_year AS (
	SELECT *FROM players_state_change
	WHERE current_season = 2020
	),
	current_year AS (
	SELECT player_name,
	current_season,
	is_active
	FROM players
	WHERE current_season = 2021
)
SELECT COALESCE(l.player_name, c.player_name) AS player_name,
	COALESCE(l.first_active_season, c.current_season) AS first_active_season,
	COALESCE(c.current_season, l.last_active_season) AS last_active_season,
	c.current_season AS current_season,
	CASE
		WHEN l.player_name IS NULL THEN 'NEW'
		WHEN c.current_season IS NULL AND l.last_active_season = l.current_season THEN 'Retired'
		WHEN l.last_active_season = c.current_season - 1 THEN 'Continued Playing'
		WHEN l.last_active_season < c.current_season - 1 THEN 'Returned from Retirement'
		ELSE 'Stay Retired'
	END AS state_change

	FROM last_year AS l 
	FULL OUTER JOIN current_year AS c
	ON l.player_name = c.player_name;

select * from players_state_change order by 1,4 DESC;
