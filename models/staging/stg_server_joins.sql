with source as (
    select * from {{ ref('raw_server_joins') }}
)

select
    cast(server_join_id as varchar) as server_join_id,
    cast(user_id as varchar)        as user_id,
    cast(server_id as varchar)      as server_id,
    cast(joined_ts as timestamp)    as joined_at,
    cast(joined_ts as date)         as joined_date
from source
