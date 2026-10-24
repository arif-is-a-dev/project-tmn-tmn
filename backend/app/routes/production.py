"""Production data read-only API."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db_session
from ..models import Produksi
from ..schemas import (
    ErrorResponse,
    ProductionBase,
    ProductionListResponse,
    ProductionSummaryResponse,
)

router = APIRouter(prefix="/api/production", tags=["production"])


def _produksi_to_dict(row: Any) -> dict[str, Any]:
    """Convert a Produksi model instance to a plain dict."""
    return {
        c.name: getattr(row, c.name)
        for c in row.__table__.columns
        if hasattr(row, c.name)
    }


@router.get(
    "",
    response_model=ProductionListResponse,
    responses={
        200: {"description": "Paginated list of production records."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_production(
    page: int = Query(1, ge=1, description="Page number (1-based)."),
    per_page: int = Query(10, ge=1, le=100, description="Items per page."),
    nama_produk: str | None = Query(None, description="Partial name search (case-insensitive)."),
    jenis_produk: str | None = Query(None, description="Filter by exact product type."),
    periode: int | None = Query(None, description="Filter by production year (e.g. 2024)."),
) -> ProductionListResponse:
    """Return a paginated list of production records from the ``produksi`` table.

    - ``nama_produk``: case-insensitive partial match on product name.
    - ``jenis_produk``: filter by exact product type.
    - ``periode``: filter by production year.
    - Results are ordered by ``periode_produksi`` descending, then ``nama_produk`` ascending.

    Note: ``jumlah_produksi_total`` is a repeated-group total and must NOT be
    summed.  The field is returned as-is for completeness but callers should
    use ``jumlah_produksi_varian`` for any aggregation.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            query = select(Produksi)
            count_query = select(func.count()).select_from(Produksi)

            if nama_produk:
                pattern = f"%{nama_produk}%"
                query = query.where(Produksi.nama_produk.ilike(pattern))
                count_query = count_query.where(Produksi.nama_produk.ilike(pattern))

            if jenis_produk:
                query = query.where(Produksi.jenis_produk == jenis_produk)
                count_query = count_query.where(Produksi.jenis_produk == jenis_produk)

            if periode:
                query = query.where(Produksi.periode_produksi == periode)
                count_query = count_query.where(Produksi.periode_produksi == periode)

            total = session.execute(count_query).scalar_one()

            offset = (page - 1) * per_page
            query = (
                query
                .order_by(Produksi.periode_produksi.desc(), Produksi.nama_produk.asc())
                .offset(offset)
                .limit(per_page)
            )

            rows = session.execute(query).scalars().all()
            items = [ProductionBase.model_validate(_produksi_to_dict(r)) for r in rows]

            return ProductionListResponse(
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
                "message": "Could not retrieve production data. Please try again later.",
            },
        ) from exc


@router.get(
    "/summary",
    response_model=ProductionSummaryResponse,
    responses={
        200: {"description": "Aggregated production summary."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def production_summary() -> ProductionSummaryResponse:
    """Return aggregated summary statistics for the ``produksi`` table.

    Metrics are computed from actual data:

    - ``total_records``: count of all rows.
    - ``distinct_products``: count of distinct ``produk_id`` values.
    - ``distinct_periods``: count of distinct ``periode_produksi`` years.
    - ``earliest_period`` / ``latest_period``: min/max production year.
    - ``total_production_varian``: sum of ``jumlah_produksi_varian``.
      ``jumlah_produksi_total`` is deliberately excluded because it is a
      repeated-group total that would overstate actual production.
    - ``total_stok``: sum of ``stok`` where it is not NULL.

    Returns zeros / nulls when the table is empty.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            # Total record count
            total_records = session.execute(
                select(func.count()).select_from(Produksi)
            ).scalar_one()

            if total_records == 0:
                return ProductionSummaryResponse(
                    total_records=0,
                    distinct_products=0,
                    distinct_periods=0,
                    earliest_period=None,
                    latest_period=None,
                    total_production_varian=0.0,
                    total_stok=None,
                )

            # Distinct counts
            distinct_products = session.execute(
                select(func.count(Produksi.produk_id.distinct()))
            ).scalar_one()
            distinct_periods = session.execute(
                select(func.count(Produksi.periode_produksi.distinct()))
            ).scalar_one()

            # Min/max period
            earliest_period: int | None = session.execute(
                select(func.min(Produksi.periode_produksi))
            ).scalar_one()
            latest_period: int | None = session.execute(
                select(func.max(Produksi.periode_produksi))
            ).scalar_one()

            # Sum of jumlah_produksi_varian (NOT jumlah_produksi_total)
            total_production_varian: float = session.execute(
                select(func.sum(Produksi.jumlah_produksi_varian))
            ).scalar_one() or 0.0

            # Sum of stok (only where NOT NULL)
            total_stok: float | None = session.execute(
                select(func.sum(Produksi.stok)).where(Produksi.stok.isnot(None))
            ).scalar_one()

            return ProductionSummaryResponse(
                total_records=total_records,
                distinct_products=distinct_products,
                distinct_periods=distinct_periods,
                earliest_period=int(earliest_period) if earliest_period else None,
                latest_period=int(latest_period) if latest_period else None,
                total_production_varian=total_production_varian,
                total_stok=total_stok,
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not compute production summary. Please try again later.",
            },
        ) from exc
