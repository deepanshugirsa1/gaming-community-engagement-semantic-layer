"""Synthetic gaming-community event generator.

Produces raw event tables that resemble what a gaming/community platform emits:
messages, voice sessions, server joins/creations, and game session start/end events.

Output is written as CSV seeds into ``seeds/`` so dbt can load them portably into
either DuckDB (local) or BigQuery. The goal is a realistic event stream to build a
semantic layer on top of -- not a perfect replica of production data.

Usage:
    python generate_events.py                 # default scale
    python generate_events.py --users 5000 --days 90 --seed 7
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

SEEDS_DIR = os.path.join(os.path.dirname(__file__), "seeds")

COUNTRIES = ["US", "BR", "DE", "GB", "IN", "JP", "KR", "CA", "FR", "MX"]
PLATFORMS = ["desktop", "mobile", "web"]
SERVER_CATEGORIES = ["gaming", "esports", "community", "study", "music", "creator"]
GAMES = ["valorant", "league", "fortnite", "apex", "minecraft", "cs2", "tft"]


def _rng(seed: int) -> np.random.Generator:
    return np.random.default_rng(seed)


def _random_timestamps(rng, start: datetime, days: int, n: int) -> np.ndarray:
    """Uniform-ish timestamps across the window with a mild evening/weekend skew."""
    offsets_days = rng.integers(0, days, size=n)
    # weight toward evening hours (16:00-23:00 UTC-ish) with a broad daytime base
    hours = np.clip(rng.normal(20, 4, size=n).astype(int), 0, 23)
    minutes = rng.integers(0, 60, size=n)
    seconds = rng.integers(0, 60, size=n)
    base = np.array([start + timedelta(days=int(d)) for d in offsets_days])
    return np.array(
        [
            b.replace(hour=int(h), minute=int(m), second=int(s))
            for b, h, m, s in zip(base, hours, minutes, seconds)
        ]
    )


def generate(users: int, servers: int, days: int, seed: int) -> dict[str, pd.DataFrame]:
    rng = _rng(seed)
    start = datetime(2025, 1, 1)

    # ---- dimensions -------------------------------------------------------
    user_ids = [f"u_{i:06d}" for i in range(users)]
    signup_offsets = rng.integers(0, days, size=users)
    users_df = pd.DataFrame(
        {
            "user_id": user_ids,
            "signup_ts": [start + timedelta(days=int(o)) for o in signup_offsets],
            "country": rng.choice(COUNTRIES, size=users),
            "signup_platform": rng.choice(PLATFORMS, size=users, p=[0.45, 0.45, 0.10]),
        }
    )

    server_ids = [f"s_{i:05d}" for i in range(servers)]
    servers_df = pd.DataFrame(
        {
            "server_id": server_ids,
            "created_ts": [
                start + timedelta(days=int(o)) for o in rng.integers(0, days, size=servers)
            ],
            "owner_user_id": rng.choice(user_ids, size=servers),
            "category": rng.choice(SERVER_CATEGORIES, size=servers),
        }
    )

    # ---- server joins (each user joins 1-6 servers) -----------------------
    join_rows = []
    joins_per_user = rng.integers(1, 7, size=users)
    for uid, k in zip(user_ids, joins_per_user):
        chosen = rng.choice(server_ids, size=int(k), replace=False)
        for sid in chosen:
            join_rows.append((uid, sid))
    joins_df = pd.DataFrame(join_rows, columns=["user_id", "server_id"])
    joins_df["joined_ts"] = _random_timestamps(rng, start, days, len(joins_df))
    joins_df.insert(0, "server_join_id", [f"j_{i:08d}" for i in range(len(joins_df))])

    # membership lookup for downstream events
    membership = joins_df[["user_id", "server_id"]].to_numpy()

    def sample_membership(n: int) -> np.ndarray:
        idx = rng.integers(0, len(membership), size=n)
        return membership[idx]

    # ---- messages ---------------------------------------------------------
    n_messages = users * rng.integers(15, 40)  # avg messages per user across window
    mem = sample_membership(n_messages)
    messages_df = pd.DataFrame(
        {
            "message_id": [f"m_{i:09d}" for i in range(n_messages)],
            "user_id": mem[:, 0],
            "server_id": mem[:, 1],
            "channel_id": [f"c_{c:06d}" for c in rng.integers(0, servers * 8, size=n_messages)],
            "sent_ts": _random_timestamps(rng, start, days, n_messages),
            "char_count": rng.integers(1, 280, size=n_messages),
        }
    )

    # ---- voice sessions ---------------------------------------------------
    n_voice = users * rng.integers(3, 9)
    mem = sample_membership(n_voice)
    voice_start = _random_timestamps(rng, start, days, n_voice)
    voice_minutes = np.clip(rng.exponential(22, size=n_voice), 1, 480).astype(int)
    voice_df = pd.DataFrame(
        {
            "voice_session_id": [f"v_{i:09d}" for i in range(n_voice)],
            "user_id": mem[:, 0],
            "server_id": mem[:, 1],
            "started_ts": voice_start,
            "ended_ts": [s + timedelta(minutes=int(m)) for s, m in zip(voice_start, voice_minutes)],
        }
    )

    # ---- game sessions as start/end events (paired downstream in dbt) -----
    n_games = users * rng.integers(4, 12)
    game_user = rng.choice(user_ids, size=n_games)
    game_ids = rng.choice(GAMES, size=n_games)
    game_start = _random_timestamps(rng, start, days, n_games)
    game_minutes = np.clip(rng.normal(35, 18, size=n_games), 2, 300).astype(int)
    game_session_ids = [f"g_{i:09d}" for i in range(n_games)]

    start_rows = pd.DataFrame(
        {
            "event_id": [f"ge_{i:09d}_s" for i in range(n_games)],
            "game_session_id": game_session_ids,
            "user_id": game_user,
            "game_id": game_ids,
            "event_type": "game_session_started",
            "event_ts": game_start,
        }
    )
    end_rows = pd.DataFrame(
        {
            "event_id": [f"ge_{i:09d}_e" for i in range(n_games)],
            "game_session_id": game_session_ids,
            "user_id": game_user,
            "game_id": game_ids,
            "event_type": "game_session_ended",
            "event_ts": [s + timedelta(minutes=int(m)) for s, m in zip(game_start, game_minutes)],
        }
    )
    # ~3% of sessions never emit an "ended" event -> realistic dangling starts
    drop_mask = rng.random(n_games) < 0.03
    end_rows = end_rows[~drop_mask]
    game_events_df = pd.concat([start_rows, end_rows], ignore_index=True)
    game_events_df = game_events_df.sort_values("event_ts").reset_index(drop=True)

    return {
        "raw_users": users_df,
        "raw_servers": servers_df,
        "raw_server_joins": joins_df,
        "raw_messages": messages_df,
        "raw_voice_sessions": voice_df,
        "raw_game_session_events": game_events_df,
    }


def _fmt_ts(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    for col in out.columns:
        if col.endswith("_ts"):
            out[col] = pd.to_datetime(out[col]).dt.strftime("%Y-%m-%d %H:%M:%S")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate synthetic gaming events.")
    parser.add_argument("--users", type=int, default=2000)
    parser.add_argument("--servers", type=int, default=150)
    parser.add_argument("--days", type=int, default=60)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    os.makedirs(SEEDS_DIR, exist_ok=True)
    tables = generate(args.users, args.servers, args.days, args.seed)

    for name, df in tables.items():
        path = os.path.join(SEEDS_DIR, f"{name}.csv")
        _fmt_ts(df).to_csv(path, index=False)
        print(f"  wrote {len(df):>8,} rows -> seeds/{name}.csv")

    total = sum(len(df) for df in tables.values())
    print(f"Done. {total:,} total rows across {len(tables)} raw tables.")


if __name__ == "__main__":
    main()
