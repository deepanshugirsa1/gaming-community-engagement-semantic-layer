# Metric Definitions (Semantic Layer)

The point of this project is one governed definition per metric — grain, logic, and
edge cases documented so every dashboard and query agrees. This is the spec the dbt
marts implement.

---

## Core engagement metrics

### Active user / DAU
- **Definition:** a user is *active* on a calendar day (UTC) if they have **≥ 1
  message, voice session, or game session** on that day.
- **Grain:** one row per `(activity_date, user_id)` in `fct_user_engagement_daily`.
- **DAU:** `count(distinct user_id)` for a given `activity_date`.
- **Edge cases:**
  - A **server join alone does not count** as engagement — joining is acquisition, not
    activity. It is tracked separately in `int_user_activity_daily` as `server_join`.
  - Timezone is UTC; day boundaries follow the event timestamp date.

### Messages sent
- **Definition:** count of `stg_messages` rows for the user-day. Additive across days
  and users.
- **Grain:** `(activity_date, user_id)`.

### Voice minutes
- **Definition:** sum of completed voice-session duration in whole minutes
  (`ended_at − started_at`).
- **Edge cases:** durations are non-negative (enforced by test); a session is attributed
  to its **start** date.

### Game sessions
- **Definition:** count of game sessions started by the user-day, from
  `int_game_sessions`.
- **Edge case:** a session with a start but no end event is still counted (it happened);
  `is_completed = false` and `duration_minutes` is null so incomplete sessions never
  corrupt duration averages.

---

## Server metrics (in progress)

### Active server (planned final definition)
- A server is *active* in a week if it has **≥ 1 message or voice session in the trailing
  7 days**. Current `mart_server_health` uses lifetime rollups as a placeholder until
  the weekly grain lands.

### Server engagement score (v0 — placeholder)
- `message_count + voice_sessions * 5`. Weights are a placeholder pending metric-owner
  sign-off; documented as `engagement_score_v0` so no one mistakes it for final.

---

## Retention metrics (planned)

### D1 / D7 / D30 retention
- **Definition:** of users first active on day *N*, the share active again on day
  *N+1 / N+7 / N+30*. Built on the shared `int_user_activity_daily` spine so retention
  and DAU count activity identically. Not yet implemented — see roadmap.

---

## Naming conventions

- `stg_*` — one row per source entity/event, typed and renamed, no business logic.
- `int_*` — reusable transformations (sessionization, daily rollups).
- `dim_*` / `fct_*` — curated marts; `fct_` are event/measure grain, `dim_` are entities.
- `mart_*` — consumer-facing metric tables for BI.
- Timestamps end in `_at`; dates end in `_date`; booleans start with `is_`.
