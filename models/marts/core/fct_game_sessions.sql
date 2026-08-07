-- WORK IN PROGRESS
-- One row per game session with duration and game/user attributes.
-- TODO: enrich with dim_users attributes (country, platform, tenure bucket) and add
--       a session_bucket (short/medium/long) once the metric owner signs off on the
--       thresholds. Left as a straightforward pass-through for now.

with sessions as (
    select * from {{ ref('int_game_sessions') }}
)

select
    game_session_id,
    user_id,
    game_id,
    started_at,
    ended_at,
    started_date,
    is_completed,
    duration_minutes
from sessions
