-- Building Slowly Changing Dimensions

select * from player_seasons limit 5;

create type season_stats as (
season integer,
gp integer,
pts real,
reb real,
ast real
)

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

select * from players limit 5;
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
ORDER BY player_name, streak_identifier

-------------------------------------------------------------------
SELECT current_season, end_season FROM players_scd
where current_season = 2021;
-------------------------------------------------------------------
CREATE TYPE scd_type AS (
scoring_class scoring_class,
is_active BOOLEAN,
start_season INTEGER,
end_season INTEGER
)
-------------------------------------------------------------------

WITH last_season_scd AS (
SELECT * FROM players_scd
WHERE current_season = 2021
AND end_season = 2021
),
historical_scd AS (
SELECT
player_name,
scoring_class,
is_active,
start_season,
end_season
FROM players_scd
WHERE current_season = 2021
AND end_season < 2021
),
this_season_data AS (
SELECT * FROM players
WHERE current_season = 2022
),
unchanged_records AS (
SELECT ts.player_name,
ts.scoring_class, ts.is_active,
ls.start_season, ts.current_season AS end_season
FROM this_season_data ts JOIN last_season_scd ls
ON ls.player_name = ts.player_name
WHERE ts.scoring_class = ls.scoring_class
AND ts.is_active = ls.is_active
),

changed_records AS (
SELECT ts.player_name,
UNNEST (ARRAY[
ROW(
ls.scoring_class,
ls.is_active,
ls.start_season,
ls.end_season
)::scd_type,
ROW(
ts.scoring_class,
ts.is_active,
ts.current_season,
ts.current_season
)::scd_type
]) AS records
FROM this_season_data ts LEFT JOIN last_season_scd ls
ON ls.player_name = ts.player_name
WHERE (ts.scoring_class <> ls.scoring_class
OR ts.is_active <> ls.is_active)
),
unnested_changed_records AS (
SELECT player_name,
(records::scd_type).scoring_class,
(records::scd_type).is_active,
(records::scd_type).start_season,
(records::scd_type).end_season
FROM changed_records
),

new_records AS (
SELECT 
ts.player_name,
ts.scoring_class,
ts.is_active,
ts.current_season AS start_season,
ts.current_season AS end_season
FROM this_season_data ts
LEFT JOIN last_season_scd ls
ON ts.player_name = ls.player_name
WHERE ls.player_name IS NULL
)

SELECT * FROM historical_scd
UNION ALL
SELECT * FROM unchanged_records
UNION ALL
SELECT * FROM unnested_changed_records
UNION ALL
SELECT * FROM new_records


