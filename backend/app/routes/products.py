"""Products catalog read-only API."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db_session
from ..models import Produk
from ..schemas import (
    ErrorResponse,
    ProductBase,
    ProductDetailResponse,
    ProductListResponse,
)

router = APIRouter(prefix="/api/products", tags=["products"])


def _product_to_dict(row: Any) -> dict[str, Any]:
    """Convert a Produk model instance to a plain dict, redacting PII."""
    d = {
        c.name: getattr(row, c.name)
        for c in row.__table__.columns
        if hasattr(row, c.name)
    }
    # Redact kontak (PII) — PRD security guideline
    d.pop("kontak", None)
    return d


@router.get(
    "",
    response_model=ProductListResponse,
    responses={
        200: {"description": "List of products, paginated."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_products(
    page: int = Query(1, ge=1, description="Page number (1-based)."),
    per_page: int = Query(10, ge=1, le=100, description="Items per page."),
    jenis_produk: str | None = Query(None, description="Filter by product type."),
    nama_produk: str | None = Query(None, description="Partial name search (case-insensitive)."),
) -> ProductListResponse:
    """Return a paginated list of products from the ``produk`` table.

    - ``jenis_produk`` filters by exact product type.
    - ``nama_produk`` performs a case-insensitive partial match.
    - ``kontak`` is never returned (PII redaction).
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            # Build filtered query
            query = select(Produk)
            count_query = select(func.count()).select_from(Produk)

            if jenis_produk:
                query = query.where(Produk.jenis_produk == jenis_produk)
                count_query = count_query.where(Produk.jenis_produk == jenis_produk)

            if nama_produk:
                filter_pattern = f"%{nama_produk}%"
                query = query.where(Produk.nama_produk.ilike(filter_pattern))
                count_query = count_query.where(Produk.nama_produk.ilike(filter_pattern))

            # Total count before pagination
            total = session.execute(count_query).scalar_one()

            # Paginate
            offset = (page - 1) * per_page
            query = query.offset(offset).limit(per_page)

            rows = session.execute(query).scalars().all()

            items = [_product_to_dict(r) for r in rows]
            # Remove kontak from each item (PII)
            for item in items:
                item.pop("kontak", None)

            return ProductListResponse(
                total=total,
                page=page,
                per_page=per_page,
                items=[ProductBase.model_validate(item) for item in items],
            )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not retrieve products. Please try again later.",
            },
        ) from exc


@router.get(
    "/{produk_id}",
    response_model=ProductDetailResponse,
    responses={
        200: {"description": "Product detail."},
        404: {"description": "Product not found.", "model": ErrorResponse},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def get_product(produk_id: str) -> ProductDetailResponse:
    """Return a single product by its primary key.

    ``kontak`` is redacted from the response (PII).

    The database session is closed BEFORE the 404 check so that pending
    exceptions never interfere with the context manager's __exit__.
    """
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    row = None
    db_error: Exception | None = None

    try:
        with get_db_session(settings) as session:
            # Lookup happens fully inside the with block; session closes
            # cleanly with no pending exception when we exit.
            row = session.get(Produk, produk_id)
    except Exception as exc:
        db_error = exc

    if db_error is not None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Database unavailable.",
                "message": "Could not retrieve the product. Please try again later.",
            },
        ) from db_error

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": f"Product '{produk_id}' not found."},
        )

    item = _product_to_dict(row)
    item.pop("kontak", None)
    return ProductDetailResponse.model_validate(item)


@router.get(
    "/jenis/list",
    response_model=list[str],
    responses={
        200: {"description": "Distinct product types in the catalog."},
    },
)
def list_jenis_produk() -> list[str]:
    """Return all distinct ``jenis_produk`` values in the catalog."""
    from ..config import DatabaseSettings

    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            rows = session.execute(
                select(Produk.jenis_produk).distinct().order_by(Produk.jenis_produk)
            ).scalars().all()
            return list(rows)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable."},
        ) from exc