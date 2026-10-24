"""Health check endpoint."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from ..database import check_database_connection
from ..schemas import ErrorResponse, HealthResponse

router = APIRouter(tags=["health"])


@router.get(
    "/api/health",
    response_model=HealthResponse,
    responses={
        200: {"description": "API is running, database is reachable."},
        503: {"description": "API is running but database is unreachable.", "model": ErrorResponse},
    },
)
def health_check() -> HealthResponse:
    """Return API and database connection status.

    No sensitive information (host, port, credentials) is included in the
    response, as required by the PRD security guidelines.
    """
    from ..config import DatabaseSettings

    # DatabaseSettings() raises RuntimeError if URL is missing or not local.
    try:
        settings = DatabaseSettings()
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "degraded",
                "database": "configuration_error",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "error": str(exc),
            },
        )

    # Probe the database with a simple SELECT 1.
    db_ok, db_message = check_database_connection(settings)

    if not db_ok:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "degraded",
                "database": "connection_failed",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "error": "Could not connect to the database. "
                         "Make sure PostgreSQL is running and credentials are correct.",
            },
        )

    return HealthResponse(
        status="ok",
        database="ok",
        timestamp=datetime.now(timezone.utc),
    )