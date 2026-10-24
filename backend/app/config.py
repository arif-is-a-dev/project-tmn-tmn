"""Database configuration for the FastAPI backend.

Uses the same VINIX7_DATABASE_URL environment variable as the ETL scripts,
so both use the same .env file without duplication.
"""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field

# Resolve .env relative to the project root (two levels up from this file)
_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(_ROOT / ".env")


class DatabaseSettings(BaseModel):
    """Validated database connection settings.

    The URL is loaded from the VINIX7_DATABASE_URL environment variable.
    Only local PostgreSQL targets are accepted.
    """

    database_url: str = Field(default="")

    def __init__(self, **kwargs):
        # Pre-populate database_url from env if not explicitly passed
        if "database_url" not in kwargs or not kwargs["database_url"]:
            kwargs["database_url"] = _get_database_url()
            _assert_local(kwargs["database_url"])
        super().__init__(**kwargs)

    @property
    def safe_info(self) -> dict[str, str]:
        """Return host/database/user WITHOUT the password for safe error messages."""
        from sqlalchemy.engine import make_url

        parsed = make_url(self.database_url)
        return {
            "driver": parsed.drivername or "",
            "host": parsed.host or "",
            "port": str(parsed.port or ""),
            "database": parsed.database or "",
            "user": parsed.username or "",
        }


def _get_database_url() -> str:
    """Return the PostgreSQL connection URL from the environment."""
    url = os.getenv("VINIX7_DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError(
            "VINIX7_DATABASE_URL is not set. "
            "Copy .env.example to .env and fill in your PostgreSQL credentials."
        )
    return url


def _assert_local(url: str) -> bool:
    """Reject non-local targets so credentials are never accidentally sent elsewhere."""
    from sqlalchemy.engine import make_url

    parsed = make_url(url)
    host = parsed.host or ""
    if host not in {"localhost", "127.0.0.1", "::1"}:
        raise RuntimeError(
            f"Backend only supports local PostgreSQL targets (localhost/127.0.0.1). "
            f"Got '{host}'."
        )
    return True


def get_database_url() -> str:
    return _get_database_url()


def is_local_database(url: str) -> bool:
    return _assert_local(url)