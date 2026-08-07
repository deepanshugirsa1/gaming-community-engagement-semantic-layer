-- WORK IN PROGRESS
-- Server-level health metrics. Currently lifetime rollups; the intended final grain is
-- (server_id, week) with trailing-7d active flags and week-over-week engagement growth.
-- TODO: add weekly grain, trailing-7d active-server definition, and churned-server flag.

with servers as (
    select * from {{ ref('dim_servers') }}
),

voice as (
    select server_id, count(*) as voice_sessions
    from {{ ref('stg_voice_sessions') }}
    group by 1
)

select
    s.server_id,
    s.category,
    s.member_count,
    s.message_count,
    s.messaging_users,
    coalesce(v.voice_sessions, 0) as voice_sessions,
    -- placeholder engagement score until weekly grain + owner-approved weights land
    s.message_count + coalesce(v.voice_sessions, 0) * 5 as engagement_score_v0
from servers s
left join voice v on s.server_id = v.server_id
