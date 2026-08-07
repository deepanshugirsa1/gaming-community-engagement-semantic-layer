with users as (
    select * from {{ ref('stg_users') }}
),

joins as (
    select
        user_id,
        count(*)      as servers_joined,
        min(joined_at) as first_join_at
    from {{ ref('stg_server_joins') }}
    group by 1
),

activity as (
    select
        user_id,
        min(activity_date) as first_active_date,
        max(activity_date) as last_active_date,
        count(distinct activity_date) as active_days
    from {{ ref('int_user_activity_daily') }}
    group by 1
)

select
    u.user_id,
    u.signup_at,
    u.signup_date,
    u.country,
    u.signup_platform,
    coalesce(j.servers_joined, 0) as servers_joined,
    j.first_join_at,
    a.first_active_date,
    a.last_active_date,
    coalesce(a.active_days, 0)    as active_days,
    coalesce(a.active_days, 0) > 0 as is_activated
from users u
left join joins j on u.user_id = j.user_id
left join activity a on u.user_id = a.user_id
