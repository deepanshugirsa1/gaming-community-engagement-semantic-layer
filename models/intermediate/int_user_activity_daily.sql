-- Unions all qualifying engagement events to a common (user_id, activity_date, event_type)
-- grain. This is the shared spine for DAU, engagement, and (later) retention metrics,
-- so every metric counts activity the same way.

with messages as (
    select user_id, sent_date as activity_date, 'message' as event_type
    from {{ ref('stg_messages') }}
),

voice as (
    select user_id, started_date as activity_date, 'voice' as event_type
    from {{ ref('stg_voice_sessions') }}
),

games as (
    select user_id, started_date as activity_date, 'game_session' as event_type
    from {{ ref('int_game_sessions') }}
),

joins as (
    select user_id, joined_date as activity_date, 'server_join' as event_type
    from {{ ref('stg_server_joins') }}
),

unioned as (
    select * from messages
    union all
    select * from voice
    union all
    select * from games
    union all
    select * from joins
)

select
    user_id,
    activity_date,
    event_type,
    count(*) as event_count
from unioned
group by 1, 2, 3
