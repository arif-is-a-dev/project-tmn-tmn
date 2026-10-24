
"""Database configuration for the FastAPI backend."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.engine import make_url

_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(_ROOT / ".env")


def _get_database_url() -> str:
    url = os.getenv("VINIX7_DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError("VINIX7_DATABASE_URL is not set.")
    return url


def _validate_database_url(url: str) -> str:
    mode = os.getenv("VINIX7_ENV", "local").strip().lower()
    parsed = make_url(url)
    host = (parsed.host or "").lower()

    if parsed.drivername not in {
        "postgresql",
        "postgresql+psycopg2",
    }:
        raise RuntimeError("A PostgreSQL connection URL is required.")

    if mode == "local":
        if host not in {"localhost", "127.0.0.1", "::1"}:
            raise RuntimeError(
                "Local mode only supports PostgreSQL on localhost."
            )
        if parsed.database != "vinix7":
            raise RuntimeError(
                "Local mode only supports the vinix7 database."
            )
    elif mode == "production":
        if not host.endswith(".neon.tech"):
            raise RuntimeError(
                "Production mode requires a Neon PostgreSQL host."
            )
        if parsed.database != "neondb":
            raise RuntimeError(
                "Production mode requires the neondb database."
            )
    else:
        raise RuntimeError("VINIX7_ENV must be local or production.")

    return url


class DatabaseSettings(BaseModel):
    """Validated database connection settings."""

    database_url: str = Field(default="", validate_default=True)

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_url(cls, value):
        url = value or _get_database_url()
        return _validate_database_url(str(url).strip())

    @property
    def safe_info(self) -> dict[str, str]:
        parsed = make_url(self.database_url)
        return {
            "driver": parsed.drivername or "",
            "host": parsed.host or "",
            "port": str(parsed.port or ""),
            "database": parsed.database or "",
            "user": parsed.username or "",
        }


def get_database_url() -> str:
    return _get_database_url()


def is_local_database(url: str) -> bool:
    try:
        _validate_database_url(url)
        return os.getenv("VINIX7_ENV", "local").strip().lower() == "local"
    except (RuntimeError, ValueError):
        return False
