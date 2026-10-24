"""Wilayah (Kalurahan & Padukuhan) read-only API."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db_session
from ..models import Kalurahan, Padukuhan
from ..schemas import (
    ErrorResponse,
    KalurahanBase,
    KalurahanListResponse,
    PadukuhanBase,
    PadukuhanListResponse,
    WilayahSummaryResponse,
)

router = APIRouter(prefix="/api/wilayah", tags=["wilayah"])


def _row_to_dict(row: Any) -> dict[str, Any]:
    """Convert a SQLAlchemy model instance to a plain dict."""
    return {
        c.name: getattr(row, c.name)
        for c in row.__table__.columns
        if hasattr(row, c.name)
    }


@router.get(
    "/kalurahan",
    response_model=KalurahanListResponse,
    responses={
        200: {"description": "Paginated list of kalurahan."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_kalurahan(
    page: int = Query(1, ge=1, description="Page number (1-based)."),
    per_page: int = Query(10, ge=1, le=100, description="Items per page."),
) -> KalurahanListResponse:
    """Return a paginated list of kalurahan records.

    Results are ordered by ``kalurahan`` name ascending.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            total = session.execute(
                select(func.count()).select_from(Kalurahan)
            ).scalar_one()

            offset = (page - 1) * per_page
            query = (
                select(Kalurahan)
                .order_by(Kalurahan.kalurahan.asc())
                .offset(offset)
                .limit(per_page)
            )

            rows = session.execute(query).scalars().all()
            items = [KalurahanBase.model_validate(_row_to_dict(r)) for r in rows]

            return KalurahanListResponse(
                total=total,
                page=page,
                per_page=per_page,
                items=items,
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not retrieve kalurahan data. Please try again later.",
            },
        ) from exc


@router.get(
    "/padukuhan",
    response_model=PadukuhanListResponse,
    responses={
        200: {"description": "Paginated list of padukuhan."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_padukuhan(
    page: int = Query(1, ge=1, description="Page number (1-based)."),
    per_page: int = Query(10, ge=1, le=100, description="Items per page."),
    kalurahan_id: str | None = Query(None, description="Filter by kalurahan ID."),
) -> PadukuhanListResponse:
    """Return a paginated list of padukuhan records.

    - ``kalurahan_id``: optional filter to restrict results to a single kalurahan.
    - Results are ordered by ``padukuhan`` name ascending.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            count_query = select(func.count()).select_from(Padukuhan)
            query = select(Padukuhan)

            if kalurahan_id:
                count_query = count_query.where(Padukuhan.kalurahan_id == kalurahan_id)
                query = query.where(Padukuhan.kalurahan_id == kalurahan_id)

            total = session.execute(count_query).scalar_one()

            offset = (page - 1) * per_page
            query = (
                query
                .order_by(Padukuhan.padukuhan.asc())
                .offset(offset)
                .limit(per_page)
            )

            rows = session.execute(query).scalars().all()
            items = [PadukuhanBase.model_validate(_row_to_dict(r)) for r in rows]

            return PadukuhanListResponse(
                total=total,
                page=page,
                per_page=per_page,
                items=items,
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not retrieve padukuhan data. Please try again later.",
            },
        ) from exc


@router.get(
    "/summary",
    response_model=WilayahSummaryResponse,
    responses={
        200: {"description": "Wilayah summary counts."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def wilayah_summary() -> WilayahSummaryResponse:
    """Return summary counts for kalurahan and padukuhan tables.

    Metrics:
    - ``total_kalurahan``: total number of kalurahan records.
    - ``total_padukuhan``: total number of padukuhan records.
    - ``kalurahan_list``: list of all kalurahan names.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            total_kalurahan = session.execute(
                select(func.count()).select_from(Kalurahan)
            ).scalar_one()

            total_padukuhan = session.execute(
                select(func.count()).select_from(Padukuhan)
            ).scalar_one()

            kalurahan_rows = session.execute(
                select(Kalurahan.kalurahan_id, Kalurahan.kalurahan)
                .order_by(Kalurahan.kalurahan.asc())
            ).all()

            kalurahan_list = [
                {"kalurahan_id": r[0], "kalurahan": r[1]}
                for r in kalurahan_rows
            ]

            return WilayahSummaryResponse(
                total_kalurahan=total_kalurahan,
                total_padukuhan=total_padukuhan,
                kalurahan_list=kalurahan_list,
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not compute wilayah summary. Please try again later.",
            },
        ) from exc
