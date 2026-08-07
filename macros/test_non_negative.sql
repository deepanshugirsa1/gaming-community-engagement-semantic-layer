{% test non_negative(model, column_name) %}
-- Fails if any value in the column is negative. Self-contained (no packages).
select {{ column_name }}
from {{ model }}
where {{ column_name }} < 0
{% endtest %}
