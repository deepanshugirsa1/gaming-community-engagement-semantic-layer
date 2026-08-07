with source as (
    select * from {{ ref('raw_game_session_events') }}
)

select
    cast(event_id as varchar)         as event_id,
    cast(game_session_id as varchar)  as game_session_id,
    cast(user_id as varchar)          as user_id,
    lower(cast(game_id as varchar))   as game_id,
    lower(cast(event_type as varchar)) as event_type,
    cast(event_ts as timestamp)       as event_at,
    cast(event_ts as date)            as event_date
from source
