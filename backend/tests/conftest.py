"""Pytest fixtures and test setup for the Vinix7 backend.

Environment loading:
  The .env file is loaded with override=True BEFORE any app modules are imported.
  This ensures VINIX7_DATABASE_URL from .env takes precedence over any prior
  os.environ value (including the fallback set below).

  Previously, setdefault() was used with a dummy password ('***'), which caused
  load_dotenv() in config.py to skip overriding it — resulting in auth failures
  and 503 errors during TestClient requests.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Generator

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient

# Add the project root to sys.path so we can import backend.app
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

# Load .env with override=True so real credentials take precedence.
# This MUST happen before importing any app module that reads env vars.
load_dotenv(_PROJECT_ROOT / ".env", override=True)

# Fallback only if .env didn't provide a URL (e.g., CI without .env file).
os.environ.setdefault(
    "VINIX7_DATABASE_URL",
    "postgresql+psycopg2://postgres:123@localhost:5432/vinix7",
)

from backend.app.main import app  # noqa: E402
from backend.app.database import dispose_engine  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def _dispose_engine_once():
    """Dispose any pre-existing engine once before the test session starts.

    This ensures a clean slate without closing a valid connection that a
    later test actually needs.
    """
    dispose_engine()
    yield
    dispose_engine()


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    """Return a FastAPI TestClient for the Vinix7 app.

    The client issues real HTTP requests against the app — no monkey-patching.
    Database calls will reach the real PostgreSQL instance when it is available,
    or return 503 gracefully when it is not.
    """
    with TestClient(app) as c:
        yield c
