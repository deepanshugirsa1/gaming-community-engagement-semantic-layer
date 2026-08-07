# Roadmap & Status

This is a portfolio project built in phases. It sits at roughly **50% of the target
scope**: the end-to-end spine runs and is tested; the higher-order metric marts,
experimentation layer, and BI exposure are next.

---

## Phase 1 — Foundations ✅ (done)

- [x] Synthetic event generator (`generate_events.py`) — users, servers, joins,
      messages, voice sessions, game start/end events, with realistic edge cases
      (dangling game sessions, evening/weekend skew).
- [x] Warehouse-portable dbt project (runs on DuckDB locally and BigQuery unchanged).
- [x] Staging layer for all six raw streams, fully typed and renamed.
- [x] Tests + descriptions on every staging model (unique/not_null/accepted_values/range).

## Phase 2 — Core model + first metric ✅ (done)

- [x] `int_game_sessions` — pairs start/end events, keeps incomplete sessions explicitly.
- [x] `int_user_activity_daily` — shared activity spine for all engagement metrics.
- [x] `dim_users`, `dim_servers`, `fct_events` (unioned engagement fact).
- [x] `fct_user_engagement_daily` — governed DAU + per-user engagement, with a
      unique-combination test on the grain.
- [x] Metric definitions documented (`docs/01_metric_definitions.md`).

## Phase 3 — Higher-order metrics 🚧 (in progress — the current ~50% line)

- [ ] `fct_game_sessions` — enrich with user attributes + session length buckets.
- [ ] `mart_server_health` — move to `(server_id, week)` grain, trailing-7d active
      server, week-over-week growth, churned-server flag.
- [ ] `mart_user_retention` — D1/D7/D30 cohort retention off the activity spine.
- [ ] Snapshotting / incremental materialization for the daily facts.

## Phase 4 — Experimentation 🔜 (planned)

- [ ] `dim_experiment` + `fct_experiment_assignment` (deterministic hash bucketing).
- [ ] Wire engagement metrics to experiment arms so a metric can be read per variant.
- [ ] Guardrail + primary-metric definitions for a mock A/B readout.

## Phase 5 — BI / semantic exposure 🔜 (planned)

- [ ] LookML (or dbt semantic-layer) exposure of the governed metrics.
- [ ] Executive engagement dashboard + a self-serve explore for PMs.

## Phase 6 — Reliability 🔜 (planned)

- [ ] Source freshness checks.
- [ ] GitHub Actions CI: `dbt build` on PRs against a scratch schema.
- [ ] `dbt docs` site published for lineage + metric discoverability.

---

## Design decisions worth calling out

- **Warehouse-portable on purpose.** Models select from seeds via `ref()` and use
  dbt's built-in cross-database macros (`dbt.datediff`), so the same SQL runs on
  DuckDB (free local dev) and BigQuery
  (the target). This keeps the project reproducible for anyone reviewing it.
- **Edge cases are explicit, not hidden.** Incomplete game sessions and
  server-join-only users are handled deliberately rather than dropped by an inner join
  — the kind of decision that decides whether stakeholders trust a metric.
- **Semantic layer first.** The whole structure optimizes for one trusted definition
  per metric with tests and docs, not for a specific dashboard.
