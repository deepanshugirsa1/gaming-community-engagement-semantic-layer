-- Pairs game_session_started / game_session_ended events into one row per session.
-- Sessions with no end event are kept (is_completed = false) so we never silently
-- drop activity -- an explicit edge case rather than an inner join that hides it.

with events as (
    select * from {{ ref('stg_game_session_events') }}
),

starts as (
    select
        game_session_id,
        user_id,
        game_id,
        event_at as started_at
    from events
    where event_type = 'game_session_started'
),

ends as (
    select
        game_session_id,
        event_at as ended_at
    from events
    where event_type = 'game_session_ended'
)

select
    s.game_session_id,
    s.user_id,
    s.game_id,
    s.started_at,
    e.ended_at,
    cast(s.started_at as date) as started_date,
    e.ended_at is not null      as is_completed,
    case
        when e.ended_at is not null
        then {{ dbt.datediff('s.started_at', 'e.ended_at', 'minute') }}
    end as duration_minutes
from starts s
left join ends e
    on s.game_session_id = e.game_session_id
