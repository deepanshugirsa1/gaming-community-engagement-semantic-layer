-- Singular test: fct_user_engagement_daily must be unique on (activity_date, user_id).
-- Returns offending rows (should be zero).
select
    activity_date,
    user_id,
    count(*) as row_count
from {{ ref('fct_user_engagement_daily') }}
group by 1, 2
having count(*) > 1
