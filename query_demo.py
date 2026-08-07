"""Quick sanity queries against the built marts (DuckDB)."""
import duckdb
import pandas as pd

pd.set_option("display.width", 160)
con = duckdb.connect("gaming.duckdb")

print("--- DAU + engagement (top 8 days) ---")
print(
    con.sql(
        """
        select activity_date,
               count(distinct user_id) as dau,
               sum(messages_sent)      as messages,
               sum(voice_minutes)      as voice_minutes,
               sum(game_sessions)      as game_sessions
        from main_marts.fct_user_engagement_daily
        group by 1
        order by 1 desc
        limit 8
        """
    ).df().to_string(index=False)
)

print("\n--- game session completeness (edge case handling) ---")
print(
    con.sql(
        """
        select is_completed,
               count(*)                    as sessions,
               round(avg(duration_minutes), 1) as avg_minutes
        from main_marts.fct_game_sessions
        group by 1
        order by 1
        """
    ).df().to_string(index=False)
)
