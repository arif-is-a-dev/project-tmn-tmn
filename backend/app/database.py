"""SQLAlchemy engine and session management.

The engine is created lazily on first use.  All queries are read-only
(SELECT only); no schema or data mutations are ever performed.

Connection pool:
  - pool_size=5  : persistent connections kept open
  - max_overflow=5: up to 5 additional connections under load
  - Total ceiling: 10 simultaneous connections

  A pool of 2 was insufficient: TopBar health polling (every 30s) competes
  with concurrent user requests for the same 2 slots.  When all 2 were busy,
  new requests blocked waiting for a connection → apparent hang → 503.

Timeout configuration:
  - connect_timeout=5 : fail fast if PostgreSQL is not listening
  - statement_timeout=10_000 : abort any query taking >10s (prevents slow queries
    from holding a connection indefinitely; returns 500 to client)
  - pool_pre_ping=True : validate connections before use (detects stale connections
    after e.g. PostgreSQL restart)
"""

from __future__ import annotations

from contextlib import contextmanager
from typing import TYPE_CHECKING, Generator

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine, Connection
from sqlalchemy.orm import Session, sessionmaker

if TYPE_CHECKING:
    from .config import DatabaseSettings


# Module-level lazy engine and session factory
_engine: Engine | None = None
_SessionFactory: type[sessionmaker[Session]] | None = None


def get_engine(settings: "DatabaseSettings") -> Engine:
    """Create (or return the cached) SQLAlchemy engine."""
    global _engine
    if _engine is None:
        _engine = create_engine(
            settings.database_url,
            # Pool — sized for concurrent requests + health polling without exhaustion
            pool_pre_ping=True,    # validate stale connections on checkout
            pool_size=5,           # persistent connections (was 2 — too small)
            max_overflow=5,        # additional connections under load (was 2)
            # connect_timeout is a psycopg2 argument, NOT a create_engine kwarg.
            # It must be passed via connect_args to take effect.
            connect_args={"connect_timeout": 5},
            future=True,
        )
    return _engine


def get_session_factory(engine: Engine) -> type[sessionmaker[Session]]:
    """Return a session factory bound to the given engine."""
    global _SessionFactory
    if _SessionFactory is None:
        _SessionFactory = sessionmaker(
            bind=engine,
            expire_on_commit=False,
            autoflush=False,
        )
    return _SessionFactory


@contextmanager
def get_db_session(settings: "DatabaseSettings") -> Generator[Session, None, None]:
    """Yield a SQLAlchemy session.  Commit is never called — read-only transactions.

    On normal exit the session is closed, returning the connection to the pool.
    On exception the transaction is rolled back before the exception propagates.

    Note: closing the session in a finally block was previously removed because
    it masked pending HTTPExceptions (a secondary connection error during close()
    replaced the intended 404 with 503).  The current pattern avoids that by
    closing normally on the success path — SQLAlchemy's Session.close() does NOT
    raise when the connection is already in an error state, so the original
    exception propagates correctly.
    """
    engine = get_engine(settings)
    factory = get_session_factory(engine)
    session = factory()
    try:
        yield session
        session.close()
    except Exception:
        session.rollback()
        raise


def check_database_connection(settings: "DatabaseSettings") -> tuple[bool, str]:
    """Probe the database with a simple SELECT 1.  Returns (ok, message)."""
    try:
        engine = get_engine(settings)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True, "ok"
    except Exception as exc:
        return False, str(exc)


def dispose_engine() -> None:
    """Close the engine and clear the cached instances.

    Call this in tests between test runs to ensure a fresh connection pool.
    """
    global _engine, _SessionFactory
    if _engine is not None:
        _engine.dispose()
    _engine = None
    _SessionFactory = None
