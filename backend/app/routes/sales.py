"""Sales / Penjualan read-only API."""

from __future__ import annotations

from datetime import date as date_type
from typing import Any

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db_session
from ..models import Penjualan
from ..schemas import (
    ErrorResponse,
    SalesBase,
    SalesListResponse,
    SalesSummaryResponse,
)

router = APIRouter(prefix="/api/sales", tags=["sales"])


def _penjualan_to_dict(row: Any) -> dict[str, Any]:
    """Convert a Penjualan model instance to a plain dict."""
    return {
        c.name: getattr(row, c.name)
        for c in row.__table__.columns
        if hasattr(row, c.name)
    }


@router.get(
    "",
    response_model=SalesListResponse,
    responses={
        200: {"description": "Paginated list of sales records."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_sales(
    page: int = Query(1, ge=1, description="Page number (1-based)."),
    per_page: int = Query(20, ge=1, le=100, description="Items per page."),
    produk_id: str | None = Query(None, description="Filter by product ID."),
    periode_start: str | None = Query(None, description="Start date filter (YYYY-MM-DD). bulan >= this date."),
    periode_end: str | None = Query(None, description="End date filter (YYYY-MM-DD). bulan <= this date."),
) -> SalesListResponse:
    """Return a paginated list of sales records from the ``penjualan`` table.

    - ``produk_id``: filter by exact product ID.
    - ``periode_start``: only include records where bulan >= this date.
    - ``periode_end``: only include records where bulan <= this date.
    - Results are ordered by ``bulan`` descending, then ``produk`` ascending.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            query = select(Penjualan)
            count_query = select(func.count()).select_from(Penjualan)

            if produk_id:
                query = query.where(Penjualan.produk_id == produk_id)
                count_query = count_query.where(Penjualan.produk_id == produk_id)

            if periode_start:
                start_date = date_type.fromisoformat(periode_start)
                query = query.where(Penjualan.bulan >= start_date)
                count_query = count_query.where(Penjualan.bulan >= start_date)

            if periode_end:
                end_date = date_type.fromisoformat(periode_end)
                query = query.where(Penjualan.bulan <= end_date)
                count_query = count_query.where(Penjualan.bulan <= end_date)

            total = session.execute(count_query).scalar_one()

            offset = (page - 1) * per_page
            query = (
                query
                .order_by(Penjualan.bulan.desc(), Penjualan.produk.asc())
                .offset(offset)
                .limit(per_page)
            )

            rows = session.execute(query).scalars().all()
            items = [SalesBase.model_validate(_penjualan_to_dict(r)) for r in rows]

            return SalesListResponse(
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
                "message": "Could not retrieve sales data. Please try again later.",
            },
        ) from exc


@router.get(
    "/summary",
    response_model=SalesSummaryResponse,
    responses={
        200: {"description": "Aggregated sales summary."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def sales_summary() -> SalesSummaryResponse:
    """Return aggregated summary statistics for the ``penjualan`` table.

    Metrics are computed from actual data:

    - ``total_records``: count of all rows.
    - ``total_revenue``: sum of ``total_penjualan``.
    - ``total_volume``: sum of ``jumlah_terjual``.
    - ``distinct_products``: count of distinct ``produk_id`` values.
    - ``period_start`` / ``period_end``: min/max bulan.
    - ``by_channel``: grouped by ``kanal`` with revenue, volume, and count.

    Returns zeros / nulls when the table is empty.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            # Total record count
            total_records = session.execute(
                select(func.count()).select_from(Penjualan)
            ).scalar_one()

            if total_records == 0:
                return SalesSummaryResponse(
                    total_records=0,
                    total_revenue=0.0,
                    total_volume=0.0,
                    distinct_products=0,
                    period_start=None,
                    period_end=None,
                    by_channel=[],
                )

            # Aggregates
            total_revenue: float = session.execute(
                select(func.sum(Penjualan.total_penjualan))
            ).scalar_one() or 0.0

            total_volume: float = session.execute(
                select(func.sum(Penjualan.jumlah_terjual))
            ).scalar_one() or 0.0

            distinct_products: int = session.execute(
                select(func.count(Penjualan.produk_id.distinct()))
            ).scalar_one()

            period_start: date_type | None = session.execute(
                select(func.min(Penjualan.bulan))
            ).scalar_one()

            period_end: date_type | None = session.execute(
                select(func.max(Penjualan.bulan))
            ).scalar_one()

            # By channel aggregation
            channel_query = (
                select(
                    Penjualan.kanal,
                    func.sum(Penjualan.total_penjualan).label("total_revenue"),
                    func.sum(Penjualan.jumlah_terjual).label("total_volume"),
                    func.count().label("count"),
                )
                .group_by(Penjualan.kanal)
                .order_by(func.sum(Penjualan.total_penjualan).desc())
            )
            channel_rows = session.execute(channel_query).all()
            by_channel = [
                {
                    "kanal": row.kanal,
                    "total_revenue": float(row.total_revenue or 0),
                    "total_volume": float(row.total_volume or 0),
                    "count": int(row.count),
                }
                for row in channel_rows
            ]

            return SalesSummaryResponse(
                total_records=total_records,
                total_revenue=float(total_revenue),
                total_volume=float(total_volume),
                distinct_products=distinct_products,
                period_start=period_start,
                period_end=period_end,
                by_channel=by_channel,
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not compute sales summary. Please try again later.",
            },
        ) from exc
