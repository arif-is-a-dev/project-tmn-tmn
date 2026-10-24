"""Organic materials read-only API with AHP-SAW ranking support.

AHP-SAW methodology from Projek_vinix.ipynb (Stages 40-44):
  K1: Ketersediaan bahan   - Benefit (weight ~0.40, simulation only)
  K2: Kontinuitas           - Benefit (weight ~0.24)
  K3: Jarak ke produksi     - Cost    (weight ~0.20) - Haversine to synthetic centroid
  K4: Kemudahan pengumpulan - Benefit (weight ~0.17)

Distance criterion (K3) is computed via Haversine using a synthetic reference
point (arithmetic centroid of 73 source padukuhan: lat=-7.6458732, lon=110.4530850).
This is NOT the actual location of any production facility. Distances are
straight-line (great-circle), not travel distances. Range: 0.48 – 8.10 km.

IMPORTANT: All AHP weights are SIMULATION ASSUMPTIONS from the notebook,
NOT expert-validated results. They must be labeled as such in any display.
The ``methodological_note`` field in the ranking response provides this
disclaimer automatically.
"""

from __future__ import annotations

from typing import Any

import numpy as np
from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select

from ..database import get_db_session
from ..models import BahanOrganik, KetersediaanBahan
from ..schemas import (
    ErrorResponse,
    OrganicAvailabilitySummary,
    OrganicCriteriaStatusResponse,
    OrganicListResponse,
    OrganicMaterialBase,
    OrganicMaterialResponse,
    OrganicRankingItem,
    OrganicRankingResponse,
    OrganicSummaryResponse,
)

router = APIRouter(prefix="/api/organic-materials", tags=["organic-materials"])

# -- AHP-SAW constants (Projek_vinix.ipynb STAGE 40, 42) ----------------------
# WARNING: SIMULATION ASSUMPTIONS - NOT expert-validated weights.
# These come from notebook Cell 308 and must be labeled as simulation
# in any user-facing display. See PRD section 6.2.

KONTINUITAS_MAP: dict[str, int] = {
    "Kontinu":       4,
    "Cukup kontinu": 3,
    "Musiman":       2,
    "Tidak kontinu": 1,
}

KEMUDAHAN_MAP: dict[str, int] = {
    "Mudah":  3,
    "Sedang": 2,
    "Sulit":  1,
}

AHP_MATRIX = np.array([
    [1,    2,   2,   2],
    [0.5,  1,   1,   2],
    [0.5,  1,   1,   1],
    [0.5,  0.5, 1,   1],
], dtype=float)

# Random Index for CR calculation (Saaty, 1980)
_RI_TABLE: dict[int, float] = {
    1: 0.0, 2: 0.0, 3: 0.58, 4: 0.90, 5: 1.12,
    6: 1.24, 7: 1.32, 8: 1.41, 9: 1.45, 10: 1.49,
}

CR_THRESHOLD = 0.10  # Maximum acceptable Consistency Ratio

CRITERIA = [
    {"code": "K1", "name": "Ketersediaan bahan",        "type": "Benefit"},
    {"code": "K2", "name": "Kontinuitas",               "type": "Benefit"},
    {"code": "K3", "name": "Jarak ke lokasi produksi",  "type": "Cost"},
    {"code": "K4", "name": "Kemudahan pengumpulan",     "type": "Benefit"},
]

KODE_KRITERIA = ["K1", "K2", "K3", "K4"]


def _compute_ahp_weights(matrix: np.ndarray) -> dict[str, float]:
    """Compute AHP weights from pairwise comparison matrix via eigenvector."""
    eigenvalues, eigenvectors = np.linalg.eig(matrix)
    max_idx = np.argmax(eigenvalues.real)
    principal = np.abs(eigenvectors[:, max_idx].real)
    weights = principal / principal.sum()
    return dict(zip(KODE_KRITERIA, weights.tolist()))


def _compute_consistency_ratio(matrix: np.ndarray) -> float:
    """Compute AHP Consistency Ratio (CR).

    CR = CI / RI where CI = (lambda_max - n) / (n - 1).
    A matrix is considered consistent when CR < 0.10.

    Returns the CR value. For n <= 2, returns 0.0 (always consistent).
    """
    n = matrix.shape[0]
    if n <= 2:
        return 0.0
    eigenvalues = np.linalg.eigvals(matrix)
    lambda_max = max(eigenvalues.real)
    ci = (lambda_max - n) / (n - 1)
    ri = _RI_TABLE.get(n, 1.49)
    if ri == 0:
        return 0.0
    return ci / ri


def _check_criteria_completeness(session) -> tuple[bool, list[str]]:
    """Check which AHP-SAW criteria have complete (non-NULL) source data.

    A criterion is incomplete if ANY record has NULL for its source column.
    This is strict: even one NULL blocks the entire ranking.
    """
    missing: list[str] = []
    k1_null = session.execute(
        select(func.count()).select_from(KetersediaanBahan)
        .where(KetersediaanBahan.jumlah_ketersediaan.is_(None))
    ).scalar_one()
    k2_null = session.execute(
        select(func.count()).select_from(KetersediaanBahan)
        .where(KetersediaanBahan.kontinuitas.is_(None))
    ).scalar_one()
    k3_null = session.execute(
        select(func.count()).select_from(KetersediaanBahan)
        .where(KetersediaanBahan.jarak_ke_produksi_km.is_(None))
    ).scalar_one()
    k4_null = session.execute(
        select(func.count()).select_from(KetersediaanBahan)
        .where(KetersediaanBahan.kemudahan_pengumpulan.is_(None))
    ).scalar_one()
    if k1_null > 0:
        missing.append("K1")
    if k2_null > 0:
        missing.append("K2")
    if k3_null > 0:
        missing.append("K3")
    if k4_null > 0:
        missing.append("K4")
    return len(missing) == 0, missing


def _build_availability_summary(session, bahan_id: str) -> dict[str, Any]:
    """Aggregate availability records for one organic material."""
    rows = session.execute(
        select(KetersediaanBahan).where(KetersediaanBahan.bahan_id == bahan_id)
    ).scalars().all()
    if not rows:
        return dict(
            total_records=0, total_quantity=0.0, satuan="",
            distinct_padukuhan=0, distinct_periods=0,
            skor_kontinuitas=None, skor_kemudahan=None,
        )
    total_qty = sum(float(r.jumlah_ketersediaan or 0) for r in rows)
    padukuhans = len({r.padukuhan_id for r in rows})
    periods = len({str(r.periode) for r in rows})
    sat = rows[0].satuan or ""
    kont_vals = [
        KONTINUITAS_MAP.get(r.kontinuitas)
        for r in rows if r.kontinuitas and r.kontinuitas in KONTINUITAS_MAP
    ]
    skor_kont = max(kont_vals) if kont_vals else None
    mudah_vals = [
        KEMUDAHAN_MAP.get(r.kemudahan_pengumpulan)
        for r in rows
        if r.kemudahan_pengumpulan and r.kemudahan_pengumpulan in KEMUDAHAN_MAP
    ]
    skor_mudah = max(mudah_vals) if mudah_vals else None
    return dict(
        total_records=len(rows), total_quantity=total_qty, satuan=sat,
        distinct_padukuhan=padukuhans, distinct_periods=periods,
        skor_kontinuitas=skor_kont, skor_kemudahan=skor_mudah,
    )


@router.get(
    "",
    response_model=OrganicListResponse,
    responses={
        200: {"description": "Paginated organic material list."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def list_organic_materials(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    jenis_bahan: str | None = Query(None, description="Filter by exact jenis_bahan_organik."),
    kategori_bahan: str | None = Query(None, description="Filter by exact kategori_bahan."),
) -> OrganicListResponse:
    """Return paginated list of organic materials with aggregated availability."""
    from ..config import DatabaseSettings
    settings = DatabaseSettings()
    try:
        with get_db_session(settings) as session:
            query = select(BahanOrganik)
            count_q = select(func.count()).select_from(BahanOrganik)
            if jenis_bahan:
                query = query.where(BahanOrganik.jenis_bahan_organik == jenis_bahan)
                count_q = count_q.where(BahanOrganik.jenis_bahan_organik == jenis_bahan)
            if kategori_bahan:
                query = query.where(BahanOrganik.kategori_bahan == kategori_bahan)
                count_q = count_q.where(BahanOrganik.kategori_bahan == kategori_bahan)
            total = session.execute(count_q).scalar_one()
            offset = (page - 1) * per_page
            query = (
                query.order_by(BahanOrganik.jenis_bahan_organik.asc())
                .offset(offset).limit(per_page)
            )
            rows = session.execute(query).scalars().all()
            items = []
            for r in rows:
                avail = _build_availability_summary(session, r.bahan_id)
                items.append(OrganicMaterialResponse(
                    bahan=OrganicMaterialBase.model_validate({
                        "bahan_id": r.bahan_id,
                        "jenis_bahan_organik": r.jenis_bahan_organik,
                        "kategori_bahan": r.kategori_bahan,
                    }),
                    availability=OrganicAvailabilitySummary(**avail),
                ))
            return OrganicListResponse(
                total=total, page=page, per_page=per_page, items=items,
            )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable.",
                    "message": "Could not retrieve organic materials."},
        ) from exc


@router.get(
    "/summary",
    response_model=OrganicSummaryResponse,
    responses={200: {"description": "Summary counts and criteria status."}},
)
def organic_summary() -> OrganicSummaryResponse:
    """Return summary counts and AHP-SAW criteria completeness."""
    from ..config import DatabaseSettings
    settings = DatabaseSettings()
    try:
        with get_db_session(settings) as session:
            total_materials = session.execute(
                select(func.count()).select_from(BahanOrganik)
            ).scalar_one()
            total_avail = session.execute(
                select(func.count()).select_from(KetersediaanBahan)
            ).scalar_one()
            with_avail = session.execute(
                select(func.count(func.distinct(KetersediaanBahan.bahan_id)))
                .select_from(KetersediaanBahan)
            ).scalar_one()
            complete, missing = _check_criteria_completeness(session)
            return OrganicSummaryResponse(
                total_materials=total_materials,
                total_availability_records=total_avail,
                materials_with_availability=with_avail,
                criteria_complete=complete,
                missing_criteria=missing,
            )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable."},
        ) from exc


@router.get(
    "/criteria-status",
    response_model=OrganicCriteriaStatusResponse,
    responses={200: {"description": "Per-criterion data availability."}},
)
def criteria_status() -> OrganicCriteriaStatusResponse:
    """Return completion status for each AHP-SAW criterion."""
    from ..config import DatabaseSettings
    settings = DatabaseSettings()
    try:
        with get_db_session(settings) as session:
            _, missing = _check_criteria_completeness(session)
            result = []
            for c in CRITERIA:
                is_missing = c["code"] in missing
                note = None
                if c["code"] == "K3" and is_missing:
                    note = "Semua nilai NULL - sumber jarak belum diverifikasi."
                result.append({
                    "code": c["code"],
                    "name": c["name"],
                    "type": c["type"],
                    "complete": not is_missing,
                    "note": note,
                })
            return OrganicCriteriaStatusResponse(criteria=result)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable."},
        ) from exc


@router.get(
    "/ranking",
    response_model=OrganicRankingResponse,
    responses={
        200: {"description": "AHP-SAW ranking or blocked status."},
        503: {"description": "Database unavailable.", "model": ErrorResponse},
    },
)
def organic_ranking() -> OrganicRankingResponse:
    """Return AHP-SAW ranking or blocked status.

    Ranking is BLOCKED when:
      1. Any criterion has NULL source data (currently K3 is 100% NULL), OR
      2. The AHP matrix fails the consistency check (CR >= 0.10).

    When blocked, no scores or rankings are fabricated.
    Weights returned are always labeled as simulation (not expert-validated).
    """
    from ..config import DatabaseSettings
    settings = DatabaseSettings()
    try:
        with get_db_session(settings) as session:
            # Check 1: Criteria completeness
            complete, missing = _check_criteria_completeness(session)
            if not complete:
                return OrganicRankingResponse(
                    status="blocked",
                    blocked_reason=(
                        "Peringkat tidak dapat dihitung karena kriteria berikut "
                        "masih memiliki data NULL: " + ", ".join(missing)
                        + ". Peringkat hanya dapat ditampilkan setelah seluruh "
                        "kriteria terisi dari sumber yang terverifikasi."
                    ),
                    missing_criteria=missing,
                    ahp_weights=None,
                    consistency_ratio=None,
                    weights_are_simulation=True,
                    items=[],
                )

            # Check 2: AHP consistency
            cr = _compute_consistency_ratio(AHP_MATRIX)
            if cr >= CR_THRESHOLD:
                return OrganicRankingResponse(
                    status="blocked",
                    blocked_reason=(
                        f"Matriks perbandingan berpasangan AHP tidak konsisten "
                        f"(CR={cr:.4f}, ambang={CR_THRESHOLD}). "
                        f"Bobot tidak dapat diandalkan tanpa revisi matriks."
                    ),
                    missing_criteria=[],
                    ahp_weights=None,
                    consistency_ratio=round(cr, 5),
                    weights_are_simulation=True,
                    items=[],
                )

            # Compute ranking
            rows = session.execute(select(BahanOrganik)).scalars().all()
            if not rows:
                return OrganicRankingResponse(
                    status="ok", blocked_reason=None,
                    missing_criteria=[], ahp_weights=None,
                    consistency_ratio=round(cr, 5),
                    weights_are_simulation=True, items=[],
                )

            # Build per-material data; skip materials with any NULL criterion
            # (defense-in-depth beyond _check_criteria_completeness)
            data = []
            for r in rows:
                avail = _build_availability_summary(session, r.bahan_id)
                jarak_rows = session.execute(
                    select(KetersediaanBahan.jarak_ke_produksi_km)
                    .where(KetersediaanBahan.bahan_id == r.bahan_id)
                    .where(KetersediaanBahan.jarak_ke_produksi_km.isnot(None))
                ).scalars().all()
                jarak_val = float(min(jarak_rows)) if jarak_rows else None

                # Skip materials with any missing criterion value
                if (avail["total_quantity"] is None
                        or avail["skor_kontinuitas"] is None
                        or jarak_val is None
                        or avail["skor_kemudahan"] is None):
                    continue

                data.append({
                    "bahan_id": r.bahan_id,
                    "jenis_bahan_organik": r.jenis_bahan_organik,
                    "kategori_bahan": r.kategori_bahan,
                    "jumlah_ketersediaan": avail["total_quantity"],
                    "skor_kontinuitas": avail["skor_kontinuitas"],
                    "skor_kemudahan": avail["skor_kemudahan"],
                    "jarak_ke_produksi_km": jarak_val,
                })

            if not data:
                return OrganicRankingResponse(
                    status="blocked",
                    blocked_reason=(
                        "Tidak ada material dengan data lengkap untuk seluruh "
                        "kriteria. Peringkat tidak dapat dihitung."
                    ),
                    missing_criteria=[],
                    ahp_weights=None,
                    consistency_ratio=round(cr, 5),
                    weights_are_simulation=True,
                    items=[],
                )

            weights = _compute_ahp_weights(AHP_MATRIX)

            # SAW normalization
            k1_vals = [d["jumlah_ketersediaan"] for d in data]
            k2_vals = [d["skor_kontinuitas"] for d in data]
            k3_vals = [d["jarak_ke_produksi_km"] for d in data]
            k4_vals = [d["skor_kemudahan"] for d in data]

            max_k1 = max(k1_vals) if k1_vals else 1
            max_k2 = max(k2_vals) if k2_vals else 1
            max_k4 = max(k4_vals) if k4_vals else 1
            min_k3 = min(k3_vals) if k3_vals else 1

            scores: list[tuple[int, float]] = []
            for i, d in enumerate(data):
                # Benefit: x / max(x)
                n1 = d["jumlah_ketersediaan"] / max_k1 if max_k1 else 0
                n2 = d["skor_kontinuitas"] / max_k2 if max_k2 else 0
                n4 = d["skor_kemudahan"] / max_k4 if max_k4 else 0
                # Cost: min(x) / x
                n3 = min_k3 / d["jarak_ke_produksi_km"] if d["jarak_ke_produksi_km"] else 0

                score = (weights["K1"] * n1 + weights["K2"] * n2
                         + weights["K3"] * n3 + weights["K4"] * n4)
                scores.append((i, round(score, 10)))

            # Sort descending by score
            scores.sort(key=lambda x: x[1], reverse=True)

            # Competition ranking (1, 1, 3): tied scores share the same rank,
            # next rank skips ahead. E.g. scores [0.9, 0.9, 0.7] -> ranks [1, 1, 3].
            items: list[OrganicRankingItem] = []
            prev_score: float | None = None
            prev_rank = 0
            for position, (idx, score) in enumerate(scores, 1):
                if prev_score is not None and abs(score - prev_score) < 1e-9:
                    rank = prev_rank  # tie: same rank
                else:
                    rank = position   # no tie: rank = position
                prev_score = score
                prev_rank = rank

                d = data[idx]
                items.append(OrganicRankingItem(
                    peringkat=rank,
                    bahan_id=d["bahan_id"],
                    jenis_bahan_organik=d["jenis_bahan_organik"],
                    kategori_bahan=d["kategori_bahan"],
                    skor_akhir=round(score, 5),
                    jumlah_ketersediaan=d["jumlah_ketersediaan"],
                    skor_kontinuitas=d["skor_kontinuitas"],
                    skor_kemudahan=d["skor_kemudahan"],
                ))

            return OrganicRankingResponse(
                status="ok",
                blocked_reason=None,
                missing_criteria=[],
                ahp_weights={k: round(v, 5) for k, v in weights.items()},
                consistency_ratio=round(cr, 5),
                weights_are_simulation=True,
                items=items,
                methodological_note=(
                    "Simulasi: K3 (jarak ke lokasi produksi) dihitung dengan Haversine "
                    "menggunakan titik referensi sintetis (centroid aritmetik 73 padukuhan "
                    "sumber), bukan lokasi aktual fasilitas produksi. Bobot AHP merupakan "
                    "asumsi simulasi, bukan hasil validasi pakar."
                ),
            )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"error": "Database unavailable."},
        ) from exc
