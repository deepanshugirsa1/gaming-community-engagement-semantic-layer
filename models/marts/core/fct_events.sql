-- Long, unioned fact of all engagement events at a common grain.
-- One row per event with a shared schema so downstream metrics and BI tools can
-- slice all engagement types consistently (event_type, user, server, timestamp).

with messages as (
    select
        message_id                as event_id,
        'message'                 as event_type,
        user_id,
        server_id,
        sent_at                   as event_at,
        sent_date                 as event_date
    from {{ ref('stg_messages') }}
),

voice as (
    select
        voice_session_id          as event_id,
        'voice'                   as event_type,
        user_id,
        server_id,
        started_at                as event_at,
        started_date              as event_date
    from {{ ref('stg_voice_sessions') }}
),

game_sessions as (
    select
        game_session_id           as event_id,
        'game_session'            as event_type,
        user_id,
        cast(null as varchar)     as server_id,
        started_at                as event_at,
        started_date              as event_date
    from {{ ref('int_game_sessions') }}
),

server_joins as (
    select
        server_join_id            as event_id,
        'server_join'             as event_type,
        user_id,
        server_id,
        joined_at                 as event_at,
        joined_date               as event_date
    from {{ ref('stg_server_joins') }}
)

select * from messages
union all
select * from voice
union all
select * from game_sessions
union all
select * from server_joins
