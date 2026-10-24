"""Pydantic schemas for API request/response validation."""

from __future__ import annotations

from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


# ─── Shared ────────────────────────────────────────────────────────────────────


class ErrorResponse(BaseModel):
    detail: str


# ─── Health ───────────────────────────────────────────────────────────────────


class HealthResponse(BaseModel):
    status: str = Field(description="'ok' when everything is healthy.")
    database: str = Field(description="'ok' when the database connection succeeds.")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


# ─── Products ─────────────────────────────────────────────────────────────────


class ProductBase(BaseModel):
    produk_id: str
    nama_produk: str
    jenis_produk: str
    deskripsi: str | None = None
    manfaat: str | None = None
    harga: float | None = None
    ukuran_kemasan: str | None = None
    produsen: str | None = None
    lokasi_produsen: str | None = None
    # kontak intentionally excluded — PII per PRD security guideline
    stok_ketersediaan: str | None = None
    foto_produk: str | None = None

    model_config = ConfigDict(from_attributes=True)


class ProductListResponse(BaseModel):
    total: int = Field(description="Total number of products matching the query.")
    page: int
    per_page: int
    items: list[ProductBase]


class ProductDetailResponse(BaseModel):
    produk_id: str
    nama_produk: str
    jenis_produk: str
    deskripsi: str | None = None
    manfaat: str | None = None
    harga: float | None = None
    ukuran_kemasan: str | None = None
    produsen: str | None = None
    lokasi_produsen: str | None = None
    # kontak intentionally excluded — PII per PRD security guideline
    stok_ketersediaan: str | None = None
    foto_produk: str | None = None


# ─── Production ─────────────────────────────────────────────────────────────────


class ProductionBase(BaseModel):
    produksi_id: str
    produk_id: str
    nama_produk: str
    jenis_produk: str
    jumlah_produksi_varian: float
    satuan: str
    kapasitas_produk: float | None = None
    bahan_baku_aktif: str | None = None
    bahan_baku: str | None = None
    jumlah_bahan_baku: float | None = None
    periode_produksi: int
    status_data: str
    satuan_bahan_baku: str | None = None
    satuan_stok: str | None = None
    stok: float | None = None

    model_config = ConfigDict(from_attributes=True)


class ProductionListResponse(BaseModel):
    """Paginated list of production records."""
    total: int = Field(description="Total records matching the query.")
    page: int
    per_page: int
    items: list[ProductionBase]


class ProductionSummaryResponse(BaseModel):
    """Aggregated production summary — computed from actual data."""
    total_records: int = Field(description="Total number of production records.")
    distinct_products: int = Field(description="Number of distinct products with production data.")
    distinct_periods: int = Field(description="Number of distinct production periods (years).")
    earliest_period: int | None = Field(description="Earliest production year in the data, or null if empty.")
    latest_period: int | None = Field(description="Latest production year in the data, or null if empty.")
    # jumlah_produksi_varian is used (NOT jumlah_produksi_total — per schema COMMENT)
    total_production_varian: float = Field(
        description="Sum of jumlah_produksi_variana across all records. "
                    "jumlah_produksi_total is a repeated-group total and is NOT summed."
    )
    total_stok: float | None = Field(
        description="Sum of stok values where stok IS NOT NULL. Null if no records have stok."
    )


# ─── Organic Materials ─────────────────────────────────────────────────────────


class OrganicMaterialBase(BaseModel):
    """A distinct organic material type from ``bahan_organik``."""
    bahan_id: str
    jenis_bahan_organik: str
    kategori_bahan: str

    model_config = ConfigDict(from_attributes=True)


class OrganicAvailabilitySummary(BaseModel):
    """Aggregated availability metrics for one material."""
    total_records: int = Field(description="Number of availability records for this material.")
    total_quantity: float = Field(description="Sum of jumlah_ketersediaan across all records.")
    satuan: str = Field(description="Unit of the quantity (tonnage).")
    distinct_padukuhan: int = Field(description="Number of distinct padukuhan with this material.")
    distinct_periods: int = Field(description="Number of distinct availability periods.")
    skor_kontinuitas: int | None = Field(
        description="Numeric score for continuity: kontinu=4, cukup kontinu=3, musiman=2, tidak kontinu=1. Null if no valid records."
    )
    skor_kemudahan: int | None = Field(
        description="Numeric score for ease: mudah=3, sedang=2, sulit=1. Null if no valid records."
    )

    model_config = ConfigDict(from_attributes=True)


class OrganicMaterialResponse(BaseModel):
    """A single organic material with its aggregated availability."""
    bahan: OrganicMaterialBase
    availability: OrganicAvailabilitySummary

    model_config = ConfigDict(from_attributes=True)


class OrganicListResponse(BaseModel):
    """Paginated list of organic materials."""
    total: int
    page: int
    per_page: int
    items: list[OrganicMaterialResponse]


class OrganicSummaryResponse(BaseModel):
    """Summary counts for the organic materials feature."""
    total_materials: int = Field(description="Number of distinct organic material types.")
    total_availability_records: int = Field(description="Total rows in ketersediaan_bahan.")
    materials_with_availability: int = Field(
        description="Number of materials that have at least one availability record."
    )
    # K3 (jarak) is computed via Haversine to a synthetic centroid reference point.
    # Ranking is blocked only if any criterion has NULL source data.
    criteria_complete: bool = Field(
        description="True when all four AHP-SAW criteria have non-NULL source data."
    )
    missing_criteria: list[str] = Field(
        description="List of criterion codes that cannot be computed due to NULL source data."
    )


class OrganicCriteriaStatusResponse(BaseModel):
    """Per-criterion availability status for AHP-SAW analysis."""
    criteria: list[dict]  # will contain {code, name, type, complete, note}


class OrganicRankingItem(BaseModel):
    """A single ranked organic material (only when ranking is unblocked)."""
    peringkat: int
    bahan_id: str
    jenis_bahan_organik: str
    kategori_bahan: str
    skor_akhir: float = Field(description="Weighted SAW score after AHP normalization.")
    jumlah_ketersediaan: float = Field(description="Sum of availability quantity.")
    skor_kontinuitas: int = Field(description="Numeric continuity score (1-4).")
    skor_kemudahan: int = Field(description="Numeric ease score (1-3).")


class OrganicRankingResponse(BaseModel):
    status: str = Field(
        description="'blocked' when criteria are incomplete or AHP inconsistent; 'ok' when ranking is computed."
    )
    blocked_reason: str | None = Field(
        description="Human-readable explanation when status is 'blocked'."
    )
    missing_criteria: list[str] = Field(
        description="Codes of criteria that are NULL in the source data."
    )
    # SIMULATION weights from notebook Cell 308 — NOT validated by domain experts.
    # Label clearly in any UI display. See PRD S6.2.
    ahp_weights: dict[str, float] | None = None
    consistency_ratio: float | None = Field(
        default=None,
        description="AHP Consistency Ratio (CR). Must be < 0.10 for valid weights. Null when blocked.",
    )
    weights_are_simulation: bool = Field(
        default=True,
        description="True if weights are simulation assumptions, not expert-validated.",
    )
    items: list[OrganicRankingItem] = Field(
        description="Ranked list when unblocked; empty when blocked."
    )
    methodological_note: str | None = Field(
        default=None,
        description="Methodological disclaimer for simulation results.",
    )

# ── Wilayah ──────────────────────────────────────────────────────────────────


class KalurahanBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    kalurahan_id: str
    kalurahan: str
    luas_kalurahan_ha: float | None = None
    jumlah_padukuhan: int | None = None
    jumlah_rw: int | None = None
    jumlah_rt: int | None = None
    batas_utara: str | None = None
    batas_selatan: str | None = None
    batas_barat: str | None = None
    batas_timur: str | None = None
    jarak_kecamatan_km: float | None = None
    jarak_kabupaten_km: float | None = None
    jarak_provinsi_km: float | None = None
    jarak_nasional_km: float | None = None
    latitude: float | None = None
    longitude: float | None = None


class PadukuhanBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    padukuhan_id: str
    kalurahan_id: str
    kalurahan: str | None = None
    padukuhan: str
    jumlah_rt: int | None = None
    jumlah_rw: int | None = None
    latitude: float | None = None
    longitude: float | None = None


class KalurahanListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    items: list[KalurahanBase]


class PadukuhanListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    items: list[PadukuhanBase]


class WilayahSummaryResponse(BaseModel):
    total_kalurahan: int
    total_padukuhan: int
    kalurahan_list: list[dict]  # [{kalurahan_id, kalurahan}] for filter dropdowns


# ── Sales / Penjualan ────────────────────────────────────────────────────────


class SalesBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    penjualan_id: str
    produk_id: str
    bulan: date
    produk: str
    jumlah_terjual: float
    harga_satuan: float
    total_penjualan: float
    satuan: str | None = None
    kanal: str | None = None
    status_data: str | None = None


class SalesListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    items: list[SalesBase]


class SalesSummaryResponse(BaseModel):
    total_records: int
    total_revenue: float
    total_volume: float
    distinct_products: int
    period_start: date | None = None
    period_end: date | None = None
    by_channel: list[dict]  # [{kanal, total_revenue, total_volume, count}]


# ── Forecasts / Prediksi Penjualan ───────────────────────────────────────────

class ForecastItem(BaseModel):
    """Single monthly prediction for one product."""
    bulan: str = Field(description="Month in YYYY-MM-DD format (first of month).")
    produk: str = Field(description="Product name.")
    produk_id: str | None = Field(default=None, description="Product ID if available.")
    prediksi_penjualan: float = Field(description="Predicted sales volume (Jumlah_Terjual).")


class ForecastSummaryResponse(BaseModel):
    """Summary of 2026 sales predictions with model metadata."""
    status: str = Field(description="'ok' if predictions generated, 'unavailable' if model missing.")
    error_message: str | None = Field(default=None, description="Error detail when status != 'ok'.")
    total_predictions: int = Field(default=0, description="Total prediction rows.")
    products_count: int = Field(default=0, description="Number of products predicted.")
    forecast_year: int = Field(default=2026, description="Forecast target year.")
    total_predicted_volume: float = Field(default=0.0, description="Sum of all predicted volumes.")
    by_month: list[dict] = Field(default_factory=list, description="Monthly totals [{bulan, total}].")
    by_product: list[dict] = Field(default_factory=list, description="Product totals [{produk, total, rata_rata}].")
    model_metadata: dict = Field(default_factory=dict, description="Training metadata and evaluation metrics.")
    quality_warning: str = Field(
        default=(
            "Prediksi ini dihasilkan oleh model ExtraTreesRegressor dengan WAPE test 58.25% "
            "(evaluasi historis tahun 2025). Hasil hanya cocok untuk perencanaan kasar, bukan "
            "akurasi yang dijamin. Prediksi bulan-bulan berikutnya menggunakan hasil prediksi "
            "sebelumnya (recursive forecasting), sehingga error dapat terakumulasi."
        ),
        description="Human-readable quality disclaimer.",
    )


class ForecastListResponse(BaseModel):
    """Paginated list of individual forecast items."""
    status: str = Field(description="'ok' or 'unavailable'.")
    error_message: str | None = Field(default=None)
    total: int = Field(default=0)
    page: int = Field(default=1)
    per_page: int = Field(default=20)
    items: list[ForecastItem] = Field(default_factory=list)
    model_metadata: dict = Field(default_factory=dict)
    quality_warning: str = Field(
        default=(
            "Prediksi ini dihasilkan oleh model ExtraTreesRegressor dengan WAPE test 58.25% "
            "(evaluasi historis tahun 2025). Hasil hanya cocok untuk perencanaan kasar. "
            "Recursive forecasting: error dapat terakumulasi pada bulan-bulan berikutnya."
        ),
    )
