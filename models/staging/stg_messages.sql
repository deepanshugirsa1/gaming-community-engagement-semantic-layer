with source as (
    select * from {{ ref('raw_messages') }}
)

select
    cast(message_id as varchar)   as message_id,
    cast(user_id as varchar)      as user_id,
    cast(server_id as varchar)    as server_id,
    cast(channel_id as varchar)   as channel_id,
    cast(sent_ts as timestamp)    as sent_at,
    cast(sent_ts as date)         as sent_date,
    cast(char_count as integer)   as char_count
from source
