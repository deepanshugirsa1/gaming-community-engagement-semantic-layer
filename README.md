# Gaming Community Engagement — Semantic Layer & Metrics (dbt + BigQuery)

A portfolio analytics-engineering project that turns raw gaming-community events
(messages, voice sessions, server joins, game sessions) into a **curated semantic
layer** of trusted fact/dimension tables and **governed metric definitions** that
product, growth, and business teams could self-serve from.

The point of this project is **not** dashboards. It is the layer *underneath* the
dashboards: raw events → staging → curated marts → metric definitions, with tests,
documentation, and consistent naming — the same analytics-engineering pattern I own
in production, applied to a gaming-community domain I care about.

> Status: **~50% complete.** The end-to-end spine (synthetic data → staging → core
> fact/dims → daily engagement metrics) runs today. Retention/cohort, server-health,
> experimentation, and the BI/LookML layer are in progress — see
> [`docs/02_roadmap.md`](docs/02_roadmap.md).

---

## Architecture

```
synthetic events (Python)                 dbt (BigQuery / DuckDB local)
─────────────────────────                 ─────────────────────────────
raw_users            ─┐
raw_servers           │      staging          intermediate         marts
raw_server_joins      ├─► stg_* (typed, ─► int_* (sessionized, ─► dim_users / dim_servers
raw_messages          │    renamed,          daily rollups)        fct_events
raw_voice_sessions    │    deduped)                                fct_game_sessions [WIP]
raw_game_session_events┘                                           fct_user_engagement_daily
                                                                   mart_server_health [WIP]
                                                                   mart_user_retention [WIP]
```

- **Warehouse:** designed for **BigQuery** (project story), and runs locally on
  **DuckDB** so the whole thing is reproducible with no cloud cost.
- **Transformation:** **dbt** — staging → intermediate → marts, with `schema.yml`
  tests and descriptions on every model.
- **Portability:** models select from dbt seeds via `ref()`, so the exact same SQL
  runs on DuckDB and BigQuery.

---

## What is done vs. in progress

| Layer | Model | Status |
|-------|-------|--------|
| Sources | 6 raw event seeds | Done |
| Staging | `stg_users`, `stg_servers`, `stg_server_joins`, `stg_messages`, `stg_voice_sessions`, `stg_game_session_events` | Done |
| Intermediate | `int_game_sessions` (pair start/end) | Done |
| Intermediate | `int_user_activity_daily` | Done |
| Marts / core | `dim_users`, `dim_servers`, `fct_events` | Done |
| Marts / core | `fct_game_sessions` | In progress |
| Marts / metrics | `fct_user_engagement_daily` (DAU, messages, voice minutes) | Done |
| Marts / metrics | `mart_server_health` | In progress |
| Marts / metrics | `mart_user_retention` (D1/D7/D30 cohorts) | Planned |
| Experimentation | `mart_experiment_assignment` + metric wiring | Planned |
| BI | LookML / metrics-layer exposure | Planned |
| Quality | freshness + CI (GitHub Actions) | Planned |

---

## Quickstart (local, DuckDB — runs in ~1 minute)

```bash
# 1. install
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 2. generate synthetic events into seeds/
python generate_events.py

# 3. build the warehouse (loads seeds, builds models, runs tests)
#    self-contained -- no dbt packages to install; local profile runs single-threaded
dbt build --profiles-dir .        # runs seed + run + test in dependency order

# 4. sanity-check the metrics (DAU + game-session edge cases)
python query_demo.py
```

Latest local run: **PASS=72, WARN=0, ERROR=0** (14 models, 52 tests, 6 seeds).

For **BigQuery**, copy `profiles.example.yml` to `~/.dbt/profiles.yml`, fill in your
project/dataset, and set `target: bigquery`. The models are unchanged.

---

## Metric definitions (the semantic layer)

Every metric has one governed definition — grain, logic, and edge cases — documented
in [`docs/01_metric_definitions.md`](docs/01_metric_definitions.md). Examples:

- **DAU** — distinct users with ≥1 qualifying engagement event on a calendar day (UTC).
- **Voice minutes** — summed completed voice-session duration, capped and dedup-safe.
- **Active server** — server with ≥1 message or voice session in the trailing 7 days.

---

## Why this project

I wanted to practice building a semantic layer from raw events to trusted business
metrics — the production analytics-engineering work I do day to day — on a domain I
actually enjoy (gaming communities). It's deliberately warehouse-portable and
test-covered so it reflects real work, not a one-off dashboard.
