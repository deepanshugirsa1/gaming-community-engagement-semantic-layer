with servers as (
    select * from {{ ref('stg_servers') }}
),

members as (
    select
        server_id,
        count(distinct user_id) as member_count
    from {{ ref('stg_server_joins') }}
    group by 1
),

msg as (
    select
        server_id,
        count(*)                as message_count,
        count(distinct user_id) as messaging_users
    from {{ ref('stg_messages') }}
    group by 1
)

select
    s.server_id,
    s.owner_user_id,
    s.created_at,
    s.created_date,
    s.category,
    coalesce(m.member_count, 0)  as member_count,
    coalesce(msg.message_count, 0) as message_count,
    coalesce(msg.messaging_users, 0) as messaging_users
from servers s
left join members m on s.server_id = m.server_id
left join msg on s.server_id = msg.server_id
