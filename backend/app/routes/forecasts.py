"""Sales forecast API — loads pre-trained model and generates predictions.

The model pipeline (.pkl) and metadata (.json) are produced by
backend/scripts/train_sales_forecast.py. This module does NOT train
or retrain the model; it only loads and uses it for inference.

Endpoints:
  GET /api/forecasts          — paginated list of monthly predictions (default 2026)
  GET /api/forecasts/summary  — aggregated summary with model metadata (default 2026)
  POST /api/forecasts/custom  — custom date range forecast with recursive multi-step prediction
"""

from __future__ import annotations

import json
import math
from datetime import date, timedelta
from pathlib import Path
import pandas as pd
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import text

from ..database import get_db_session
from ..schemas import (
    ErrorResponse,
    ForecastItem,
    ForecastListResponse,
    ForecastSummaryResponse,
)

router = APIRouter(prefix="/api/forecasts", tags=["forecasts"])

# Model artifact paths (relative to project root)
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_MODEL_PATH = _PROJECT_ROOT / "models" / "sales_forecast_pipeline.pkl"
_META_PATH = _PROJECT_ROOT / "models" / "sales_forecast_metadata.json"

# Maximum forecast horizon in months — beyond this, recursive error accumulation
# makes predictions unreliable. 24 months = 2 years past training data end.
MAX_FORECAST_MONTHS = 36

QUALITY_WARNING = (
    "Prediksi ini dihasilkan oleh model ExtraTreesRegressor dengan WAPE test 58.25% "
    "(evaluasi historis tahun 2025). Hasil hanya cocok untuk perencanaan kasar, bukan "
    "akurasi yang dijamin. Prediksi bulan-bulan berikutnya menggunakan hasil prediksi "
    "sebelumnya (recursive forecasting), sehingga error dapat terakumulasi."
)

QUALITY_WARNING_CUSTOM = (
    "Prediksi custom range menggunakan recursive forecasting: setiap bulan diprediksi "
    "menggunakan nilai prediksi bulan sebelumnya sebagai fitur lag. Semakin jauh dari "
    "data historis terakhir (Desember 2025), semakin besar akumulasi error. "
    "Untuk periode setelah 2026, lag_12 juga menggunakan nilai prediksi, bukan aktual. "
    "WAPE test model pada data 2025 adalah 58.25%. Gunakan hasil ini hanya untuk "
    "perencanaan skenario, bukan sebagai proyeksi akurat."
)


def _load_model_and_metadata():
    """Load the trained pipeline and metadata. Raises HTTPException if unavailable."""
    if not _MODEL_PATH.exists():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Model file not found.",
                "message": (
                    f"Pipeline file tidak ditemukan di {_MODEL_PATH.name}. "
                    "Jalankan backend/scripts/train_sales_forecast.py terlebih dahulu."
                ),
            },
        )
    if not _META_PATH.exists():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "Metadata file not found.",
                "message": f"Metadata file tidak ditemukan di {_META_PATH.name}.",
            },
        )

    try:
        import joblib
        pipeline = joblib.load(_MODEL_PATH)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Failed to load model.", "message": str(exc)},
        ) from exc

    try:
        with open(_META_PATH, "r", encoding="utf-8") as f:
            metadata = json.load(f)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Failed to load metadata.", "message": str(exc)},
        ) from exc

    return pipeline, metadata


def _load_historical_data() -> pd.DataFrame:
    """Load penjualan data from PostgreSQL for lag initialization."""
    from ..config import DatabaseSettings
    settings = DatabaseSettings()

    try:
        with get_db_session(settings) as session:
            rows = session.execute(text(
                "SELECT produk, produk_id, bulan, jumlah_terjual "
                "FROM penjualan ORDER BY produk, bulan"
            )).all()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable.", "message": str(exc)},
        ) from exc

    if not rows:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "No historical data.", "message": "Tabel penjualan kosong."},
        )

    df = pd.DataFrame(rows, columns=["Produk", "produk_id", "Bulan", "Jumlah_Terjual"])
    df["Bulan"] = pd.to_datetime(df["Bulan"])
    df["Jumlah_Terjual"] = df["Jumlah_Terjual"].astype(float)
    return df


def _generate_predictions(
    pipeline,
    metadata: dict,
    start_year: int = 2026,
    start_month: int = 1,
    end_year: int = 2026,
    end_month: int = 12,
    product_filter: str | None = None,
) -> list[dict]:
    """Generate recursive forecast for a custom month range using the trained pipeline.

    Parameters
    ----------
    start_year, start_month : int
        First period to predict (inclusive). Day is always normalized to 1st.
    end_year, end_month : int
        Last period to predict (inclusive).
    product_filter : str or None
        If set, only generate predictions for products whose name contains this
        substring (case-insensitive). None means all products.

    Returns list of dicts with keys: bulan, produk, produk_id, prediksi_penjualan.
    Negative predictions are clamped to 0.0 (documented, not silent).

    The recursive mechanism works as follows:
    - For each product, take the last 12 actual historical values as initial window.
    - For each target month in chronological order:
      1. Extract lag_1, lag_2, lag_3, lag_12 from the sliding window.
      2. Predict using the trained pipeline.
      3. Clamp negative to 0.
      4. Append prediction to window and trim to 12 elements.
    - This means predictions beyond the first few months use previously predicted
      values as lag inputs, causing error accumulation over longer horizons.
    """
    df = _load_historical_data()
    products = sorted(df["Produk"].unique())

    # Apply product filter if specified
    if product_filter:
        q = product_filter.lower()
        products = [p for p in products if q in p.lower()]
        if not products:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={
                    "error": "Product not found.",
                    "message": f"Tidak ada produk yang cocok dengan filter '{product_filter}'.",
                },
            )

    # Build produk_id lookup
    pid_map = {}
    for _, row in df.drop_duplicates("Produk").iterrows():
        pid_map[row["Produk"]] = row["produk_id"]

    # Build list of target (year, month) pairs in chronological order
    targets = []
    y, m = start_year, start_month
    while (y, m) <= (end_year, end_month):
        targets.append((y, m))
        m += 1
        if m > 12:
            m = 1
            y += 1

    predictions = []

    for produk in products:
        prod_history = df[df["Produk"] == produk].sort_values("Bulan")
        recent = prod_history["Jumlah_Terjual"].tail(12).tolist()

        for year, month in targets:
            lag_1 = recent[-1] if len(recent) >= 1 else 0
            lag_2 = recent[-2] if len(recent) >= 2 else 0
            lag_3 = recent[-3] if len(recent) >= 3 else 0
            lag_12 = recent[-12] if len(recent) >= 12 else 0

            input_row = pd.DataFrame([{
                "Produk": produk,
                "bulan_kalender": month,
                "lag_1": lag_1,
                "lag_2": lag_2,
                "lag_3": lag_3,
                "lag_12": lag_12,
            }])

            pred = float(pipeline.predict(input_row)[0])
            # Clamp negative predictions to 0 — documented behavior
            if pred < 0:
                pred = 0.0
            pred = round(pred, 2)

            predictions.append({
                "bulan": f"{year}-{month:02d}-01",
                "produk": produk,
                "produk_id": pid_map.get(produk),
                "prediksi_penjualan": pred,
            })

            recent.append(pred)
            if len(recent) > 12:
                recent.pop(0)

    return predictions


@router.get(
    "/summary",
    response_model=ForecastSummaryResponse,
    responses={
        200: {"description": "Forecast summary with model metadata."},
        503: {"description": "Model or database unavailable.", "model": ErrorResponse},
    },
)
def forecast_summary() -> ForecastSummaryResponse:
    """Return aggregated 2026 forecast summary with model evaluation metrics.

    Includes per-month and per-product breakdowns, plus quality warning.
    """
    pipeline, metadata = _load_model_and_metadata()
    predictions = _generate_predictions(pipeline, metadata)

    df_pred = pd.DataFrame(predictions)

    # By month
    by_month = []
    for bulan, group in df_pred.groupby("bulan"):
        by_month.append({
            "bulan": bulan,
            "total": round(group["prediksi_penjualan"].sum(), 2),
        })
    by_month.sort(key=lambda x: x["bulan"])

    # By product
    by_product = []
    for produk, group in df_pred.groupby("produk"):
        by_product.append({
            "produk": produk,
            "total": round(group["prediksi_penjualan"].sum(), 2),
            "rata_rata": round(group["prediksi_penjualan"].mean(), 2),
        })
    by_product.sort(key=lambda x: x["total"], reverse=True)

    return ForecastSummaryResponse(
        status="ok",
        error_message=None,
        total_predictions=len(predictions),
        products_count=df_pred["produk"].nunique(),
        forecast_year=2026,
        total_predicted_volume=round(df_pred["prediksi_penjualan"].sum(), 2),
        by_month=by_month,
        by_product=by_product,
        model_metadata=metadata,
        quality_warning=QUALITY_WARNING,
    )


@router.get(
    "",
    response_model=ForecastListResponse,
    responses={
        200: {"description": "Paginated forecast items."},
        503: {"description": "Model or database unavailable.", "model": ErrorResponse},
    },
)
def forecast_list(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=200),
    produk: str | None = Query(None, description="Filter by product name (partial match)."),
    bulan: str | None = Query(None, description="Filter by month (YYYY-MM-DD)."),
) -> ForecastListResponse:
    """Return paginated list of 2026 monthly predictions per product.

    Supports filtering by product name (case-insensitive partial match)
    and by month (exact match, YYYY-MM-DD format).
    """
    pipeline, metadata = _load_model_and_metadata()
    predictions = _generate_predictions(pipeline, metadata)

    # Apply filters
    filtered = predictions
    if produk:
        q = produk.lower()
        filtered = [p for p in filtered if q in p["produk"].lower()]
    if bulan:
        filtered = [p for p in filtered if p["bulan"] == bulan]

    total = len(filtered)
    offset = (page - 1) * per_page
    page_items = filtered[offset : offset + per_page]

    items = [ForecastItem(**p) for p in page_items]

    return ForecastListResponse(
        status="ok",
        error_message=None,
        total=total,
        page=page,
        per_page=per_page,
        items=items,
        model_metadata=metadata,
        quality_warning=QUALITY_WARNING,
    )


# ── Custom date range forecast ────────────────────────────────────────────────

class ForecastCustomRequest(BaseModel):
    """Request body for custom date range forecasting."""
    start_date: str = Field(
        description="Start date in YYYY-MM-DD format. Only year-month is used; day is ignored.",
        examples=["2026-03-15"],
    )
    end_date: str = Field(
        description="End date in YYYY-MM-DD format. Only year-month is used; day is ignored.",
        examples=["2027-08-20"],
    )
    produk: str | None = Field(
        default=None,
        description="Optional product name filter (case-insensitive partial match). Omit for all products.",
    )

    @field_validator("start_date", "end_date")
    @classmethod
    def validate_date_format(cls, v: str) -> str:
        try:
            date.fromisoformat(v)
        except (ValueError, TypeError):
            raise ValueError(f"Invalid date format: '{v}'. Expected YYYY-MM-DD.")
        return v


class ForecastCustomResponse(BaseModel):
    """Response for custom date range forecast."""
    status: str = Field(description="'ok' on success.")
    error_message: str | None = Field(default=None)
    start_period: str = Field(description="First predicted month (YYYY-MM-DD).")
    end_period: str = Field(description="Last predicted month (YYYY-MM-DD).")
    total_months: int = Field(description="Number of monthly periods predicted.")
    products_count: int = Field(description="Number of products in results.")
    total_predictions: int = Field(description="Total prediction rows (months × products).")
    total_predicted_volume: float = Field(description="Sum of all predicted volumes.")
    by_month: list[dict] = Field(description="Monthly totals [{bulan, total}].")
    by_product: list[dict] = Field(description="Product totals [{produk, total, rata_rata}].")
    items: list[ForecastItem] = Field(description="All individual predictions.")
    model_metadata: dict = Field(default_factory=dict)
    quality_warning: str = Field(description="Quality disclaimer for custom range forecasts.")


@router.post(
    "/custom",
    response_model=ForecastCustomResponse,
    responses={
        200: {"description": "Custom range forecast results."},
        400: {"description": "Invalid date range or parameters.", "model": ErrorResponse},
        404: {"description": "Product filter matched no products.", "model": ErrorResponse},
        422: {"description": "Validation error.", "model": ErrorResponse},
        503: {"description": "Model or database unavailable.", "model": ErrorResponse},
    },
)
def forecast_custom(request: ForecastCustomRequest) -> ForecastCustomResponse:
    """Generate recursive forecast for a custom date range.

    Accepts start and end dates (YYYY-MM-DD). Only the year-month portion is used;
    the day component is ignored (monthly granularity only).

    The forecast uses recursive multi-step prediction: each month's prediction feeds
    back as lag features for subsequent months. For periods beyond December 2026,
    lag_12 will use predicted values rather than actuals, increasing uncertainty.

    Maximum allowed range: {max_months} months from the first requested period.
    """.format(max_months=MAX_FORECAST_MONTHS)

    # Parse dates — extract year/month only
    start_dt = date.fromisoformat(request.start_date)
    end_dt = date.fromisoformat(request.end_date)

    start_year, start_month = start_dt.year, start_dt.month
    end_year, end_month = end_dt.year, end_dt.month

    # Validate: end must not be before start
    if (end_year, end_month) < (start_year, start_month):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "Invalid date range.",
                "message": (
                    f"Tanggal akhir ({request.end_date}) tidak boleh sebelum "
                    f"tanggal mulai ({request.start_date})."
                ),
            },
        )

    # Count months in range
    total_months = (end_year - start_year) * 12 + (end_month - start_month) + 1

    if total_months > MAX_FORECAST_MONTHS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "Range too long.",
                "message": (
                    f"Rentang {total_months} bulan melampaui batas maksimum "
                    f"{MAX_FORECAST_MONTHS} bulan. Kurangi rentang tanggal."
                ),
            },
        )

    pipeline, metadata = _load_model_and_metadata()

    # Generate predictions — may raise HTTPException for product not found
    predictions = _generate_predictions(
        pipeline, metadata,
        start_year=start_year,
        start_month=start_month,
        end_year=end_year,
        end_month=end_month,
        product_filter=request.produk,
    )

    df_pred = pd.DataFrame(predictions)

    # By month
    by_month = []
    for bulan, group in df_pred.groupby("bulan"):
        by_month.append({
            "bulan": bulan,
            "total": round(group["prediksi_penjualan"].sum(), 2),
        })
    by_month.sort(key=lambda x: x["bulan"])

    # By product
    by_product = []
    for produk, group in df_pred.groupby("produk"):
        by_product.append({
            "produk": produk,
            "total": round(group["prediksi_penjualan"].sum(), 2),
            "rata_rata": round(group["prediksi_penjualan"].mean(), 2),
        })
    by_product.sort(key=lambda x: x["total"], reverse=True)

    # Build start/end period strings
    start_period = f"{start_year}-{start_month:02d}-01"
    end_period = f"{end_year}-{end_month:02d}-01"

    items = [ForecastItem(**p) for p in predictions]

    return ForecastCustomResponse(
        status="ok",
        error_message=None,
        start_period=start_period,
        end_period=end_period,
        total_months=total_months,
        products_count=df_pred["produk"].nunique(),
        total_predictions=len(predictions),
        total_predicted_volume=round(df_pred["prediksi_penjualan"].sum(), 2),
        by_month=by_month,
        by_product=by_product,
        items=items,
        model_metadata=metadata,
        quality_warning=QUALITY_WARNING_CUSTOM,
    )
