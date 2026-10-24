"""Shared PostgreSQL safety helpers for Vinix7 scripts."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine, make_url


ROOT = Path(__file__).resolve().parents[1]
ENV_VAR = "VINIX7_DATABASE_URL"


def load_environment() -> None:
    load_dotenv(ROOT / ".env")


def database_url() -> str:
    value = os.getenv(ENV_VAR, "").strip()
    if not value:
        raise RuntimeError(
            f"{ENV_VAR} belum diatur. Salin .env.example menjadi .env dan isi kredensial lokal."
        )
    return value


def target_info(url: str) -> dict[str, Any]:
    parsed = make_url(url)
    return {
        "driver": parsed.drivername,
        "host": parsed.host or "",
        "port": parsed.port or 5432,
        "database": parsed.database or "",
        "user": parsed.username or "",
    }


def assert_local_vinix7(url: str) -> dict[str, Any]:
    parsed = make_url(url)
    info = target_info(url)
    if parsed.get_backend_name() != "postgresql":
        raise RuntimeError("Target harus PostgreSQL.")
    if parsed.drivername not in {"postgresql", "postgresql+psycopg2"}:
        raise RuntimeError("Driver harus postgresql+psycopg2.")
    if info["host"] not in {"localhost", "127.0.0.1", "::1"}:
        raise RuntimeError("Target harus PostgreSQL lokal (localhost/127.0.0.1).")
    if info["database"] != "vinix7":
        raise RuntimeError("Nama database harus tepat 'vinix7'.")
    if not info["user"]:
        raise RuntimeError("User PostgreSQL tidak boleh kosong.")
    return info


def make_engine(url: str) -> Engine:
    return create_engine(url, pool_pre_ping=True, future=True)


def schema_report(engine: Engine, table_columns: dict[str, list[str]],
                  extra_tables: list[str] | None = None) -> dict[str, Any]:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names(schema="public"))
    expected_tables = set(table_columns) | set(extra_tables or [])
    missing_tables = sorted(expected_tables - existing_tables)
    columns: dict[str, Any] = {}
    for table, expected in table_columns.items():
        if table not in existing_tables:
            columns[table] = {"missing_table": True}
            continue
        actual = [column["name"] for column in inspector.get_columns(table, schema="public")]
        columns[table] = {
            "missing_columns": sorted(set(expected) - set(actual)),
            "extra_columns": sorted(set(actual) - set(expected)),
        }
    return {
        "existing_tables": sorted(existing_tables),
        "missing_tables": missing_tables,
        "columns": columns,
    }


def assert_schema(engine: Engine, table_columns: dict[str, list[str]],
                  extra_tables: list[str] | None = None) -> dict[str, Any]:
    report = schema_report(engine, table_columns, extra_tables)
    if report["missing_tables"]:
        raise RuntimeError(f"Tabel belum ada: {report['missing_tables']}")
    bad = {
        table: details["missing_columns"]
        for table, details in report["columns"].items()
        if details.get("missing_columns")
    }
    if bad:
        raise RuntimeError(f"Kolom wajib belum ada: {bad}")
    return report


def clean_value(value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, pd.Timestamp):
        return value.to_pydatetime()
    if isinstance(value, np.generic):
        value = value.item()
    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass
    return value


def upsert_frame(conn: Any, table: str, frame: pd.DataFrame, primary_key: str,
                 chunk_size: int = 500) -> int:
    if frame.empty:
        return 0
    columns = list(frame.columns)
    quoted_columns = ", ".join(f'"{column}"' for column in columns)
    placeholders = ", ".join(f":{column}" for column in columns)
    update_columns = [column for column in columns if column != primary_key]
    if update_columns:
        updates = ", ".join(f'"{column}" = EXCLUDED."{column}"' for column in update_columns)
        conflict = f'ON CONFLICT ("{primary_key}") DO UPDATE SET {updates}'
    else:
        conflict = f'ON CONFLICT ("{primary_key}") DO NOTHING'
    statement = text(
        f'INSERT INTO "{table}" ({quoted_columns}) VALUES ({placeholders}) {conflict}'
    )
    records = [
        {column: clean_value(row[column]) for column in columns}
        for row in frame.to_dict("records")
    ]
    for start in range(0, len(records), chunk_size):
        conn.execute(statement, records[start:start + chunk_size])
    return len(records)


def sanitize_error(error: BaseException, url: str) -> str:
    message = str(error)
    password = make_url(url).password
    if password:
        message = message.replace(password, "***")
    return message
