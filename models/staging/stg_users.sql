with source as (
    select * from {{ ref('raw_users') }}
)

select
    cast(user_id as varchar)            as user_id,
    cast(signup_ts as timestamp)        as signup_at,
    cast(signup_ts as date)             as signup_date,
    lower(cast(country as varchar))     as country,
    lower(cast(signup_platform as varchar)) as signup_platform
from source
