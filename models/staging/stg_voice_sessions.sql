with source as (
    select * from {{ ref('raw_voice_sessions') }}
),

typed as (
    select
        cast(voice_session_id as varchar) as voice_session_id,
        cast(user_id as varchar)          as user_id,
        cast(server_id as varchar)        as server_id,
        cast(started_ts as timestamp)     as started_at,
        cast(ended_ts as timestamp)       as ended_at,
        cast(started_ts as date)          as started_date
    from source
)

select
    voice_session_id,
    user_id,
    server_id,
    started_at,
    ended_at,
    started_date,
    {{ dbt.datediff('started_at', 'ended_at', 'minute') }} as duration_minutes
from typed
