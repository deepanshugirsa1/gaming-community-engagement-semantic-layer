-- Daily engagement metrics at (activity_date, user_id) grain.
-- This is the governed source for DAU and per-user engagement. Metric definitions:
--   * a user is "active" on a day if they have >= 1 message, voice, or game session
--     (server_join alone does not count as engagement -- see docs/01_metric_definitions.md)
--   * messages_sent / voice_minutes / game_sessions are additive daily measures

with activity as (
    select * from {{ ref('int_user_activity_daily') }}
),

messages as (
    select user_id, sent_date as activity_date, count(*) as messages_sent
    from {{ ref('stg_messages') }}
    group by 1, 2
),

voice as (
    select
        user_id,
        started_date as activity_date,
        count(*)              as voice_sessions,
        sum(duration_minutes) as voice_minutes
    from {{ ref('stg_voice_sessions') }}
    group by 1, 2
),

games as (
    select user_id, started_date as activity_date, count(*) as game_sessions
    from {{ ref('int_game_sessions') }}
    group by 1, 2
),

-- one row per active user-day across engagement event types (excludes server_join)
spine as (
    select distinct user_id, activity_date
    from activity
    where event_type in ('message', 'voice', 'game_session')
)

select
    s.activity_date,
    s.user_id,
    coalesce(m.messages_sent, 0)  as messages_sent,
    coalesce(v.voice_sessions, 0) as voice_sessions,
    coalesce(v.voice_minutes, 0)  as voice_minutes,
    coalesce(g.game_sessions, 0)  as game_sessions,
    true                          as is_active_user
from spine s
left join messages m on s.user_id = m.user_id and s.activity_date = m.activity_date
left join voice v    on s.user_id = v.user_id and s.activity_date = v.activity_date
left join games g    on s.user_id = g.user_id and s.activity_date = g.activity_date
