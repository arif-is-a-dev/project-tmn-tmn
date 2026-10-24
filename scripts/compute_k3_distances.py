"""Compute K3 (jarak_ke_produksi_km) for AHP-SAW using Haversine distances.

METHODOLOGICAL NOTE
-------------------
This script computes synthetic distance values for research/simulation purposes.
The production reference point is the arithmetic centroid of 73 source padukuhan
coordinates — it is NOT the actual location of CV. Pendawa Kencana Multi Farm.

All ranking results derived from these distances are SIMULATIONS and must be
labeled as such in any report or display.

Usage:
    # Preview only (no database changes):
    python scripts/compute_k3_distances.py --preview

    # Write to database (requires explicit confirmation):
    python scripts/compute_k3_distances.py --write --confirm
"""

from __future__ import annotations

import argparse
import statistics
import sys
from pathlib import Path
from typing import Any

# Ensure project root is on sys.path for imports
_PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

from sqlalchemy import text

from backend.app.geo import haversine
from scripts.db_utils import (
    assert_local_vinix7,
    database_url,
    load_environment,
    make_engine,
    sanitize_error,
)

# ── Synthetic production reference point ───────────────────────────────────────
# Arithmetic centroid of 73 padukuhan that appear in ketersediaan_bahan.
# This is NOT the actual location of any production facility.
# Computed as: mean(latitude), mean(longitude) WHERE padukuhan_id IN ketersediaan_bahan
PRODUCTION_REF_LAT = -7.6458732
PRODUCTION_REF_LON = 110.4530850
PRODUCTION_REF_LABEL = "Centroid aritmetik 73 padukuhan sumber bahan organik"

# Sanity limits for intra-kecamatan distances
MAX_REASONABLE_KM = 20.0


def _fetch_kb_padukuhan_coords(conn) -> list[dict[str, Any]]:
    """Fetch all 88 ketersediaan_bahan rows joined with padukuhan coordinates.

    Returns list of dicts with keys:
        ketersediaan_id, bahan_id, padukuhan_id, padukuhan, kalurahan,
        latitude, longitude, jarak_ke_produksi_km (current value)
    """
    result = conn.execute(text("""
        SELECT
            kb.ketersediaan_id,
            kb.bahan_id,
            kb.padukuhan_id,
            p.padukuhan,
            p.kalurahan,
            p.latitude,
            p.longitude,
            kb.jarak_ke_produksi_km
        FROM ketersediaan_bahan kb
        JOIN padukuhan p ON kb.padukuhan_id = p.padukuhan_id
        ORDER BY kb.ketersediaan_id
    """)).fetchall()

    return [
        {
            "ketersediaan_id": row[0],
            "bahan_id": row[1],
            "padukuhan_id": row[2],
            "padukuhan": row[3],
            "kalurahan": row[4],
            "latitude": float(row[5]) if row[5] is not None else None,
            "longitude": float(row[6]) if row[6] is not None else None,
            "jarak_existing": float(row[7]) if row[7] is not None else None,
        }
        for row in result
    ]


def compute_distances(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Compute Haversine distance from each row's padukuhan to the reference point.

    Returns the same list with 'jarak_computed' added to each dict.
    Raises ValueError if any coordinate is missing or distance exceeds sanity limit.
    """
    for row in rows:
        lat = row["latitude"]
        lon = row["longitude"]

        if lat is None or lon is None:
            raise ValueError(
                f"Padukuhan {row['padukuhan_id']} ({row['padukuhan']}) "
                f"tidak memiliki koordinat lengkap."
            )

        # Check if padukuhan coincides exactly with reference point
        if lat == PRODUCTION_REF_LAT and lon == PRODUCTION_REF_LON:
            raise ValueError(
                f"Padukuhan {row['padukuhan_id']} ({row['padukuhan']}) memiliki "
                f"koordinat identik dengan titik referensi produksi. "
                f"Jarak = 0 tidak valid untuk kriteria biaya SAW."
            )

        dist = haversine(lat, lon, PRODUCTION_REF_LAT, PRODUCTION_REF_LON)

        if dist is None:
            raise ValueError(
                f"Haversine returned None for {row['padukuhan_id']}"
            )

        if dist < 0:
            raise ValueError(
                f"Jarak negatif ({dist} km) untuk {row['padukuhan_id']}"
            )

        if dist > MAX_REASONABLE_KM:
            raise ValueError(
                f"Jarak {dist:.4f} km melebihi batas kewajaran "
                f"{MAX_REASONABLE_KM} km untuk {row['padukuhan_id']} "
                f"({row['padukuhan']}, {row['kalurahan']})"
            )

        row["jarak_computed"] = dist

    return rows


def print_preview(rows: list[dict[str, Any]]) -> None:
    """Print preview table and statistics without modifying anything."""
    distances = [r["jarak_computed"] for r in rows]

    print("=" * 90)
    print("K3 DISTANCE PREVIEW — SIMULATION ONLY")
    print("=" * 90)
    print(f"Reference point: ({PRODUCTION_REF_LAT}, {PRODUCTION_REF_LON})")
    print(f"Description:     {PRODUCTION_REF_LABEL}")
    print(f"Method:          Haversine (R = 6371.0 km)")
    print(f"Total rows:      {len(rows)}")
    print()

    # Statistics
    print("--- STATISTICS ---")
    print(f"  Min:    {min(distances):.4f} km")
    print(f"  Max:    {max(distances):.4f} km")
    print(f"  Mean:   {statistics.mean(distances):.4f} km")
    print(f"  Median: {statistics.median(distances):.4f} km")
    print(f"  Stdev:  {statistics.stdev(distances):.4f} km")
    print()

    # Per-kalurahan breakdown
    kal_groups: dict[str, list[float]] = {}
    for r in rows:
        kal_groups.setdefault(r["kalurahan"], []).append(r["jarak_computed"])

    print("--- PER-KALURAHAN ---")
    print(f"  {'Kalurahan':<15} {'n':>3} {'Min':>7} {'Max':>7} {'Mean':>7}")
    print(f"  {'-'*15} {'-'*3} {'-'*7} {'-'*7} {'-'*7}")
    for kal in sorted(kal_groups.keys()):
        ds = kal_groups[kal]
        print(f"  {kal:<15} {len(ds):>3} {min(ds):>7.2f} {max(ds):>7.2f} {statistics.mean(ds):>7.2f}")
    print()

    # Full detail table
    print("--- DETAIL (88 rows) ---")
    print(f"  {'ID':<12} {'Padukuhan':<20} {'Kalurahan':<15} {'Lat':>10} {'Lon':>10} {'Dist (km)':>10} {'Existing':>10}")
    print(f"  {'-'*12} {'-'*20} {'-'*15} {'-'*10} {'-'*10} {'-'*10} {'-'*10}")
    for r in rows:
        existing = f"{r['jarak_existing']:.2f}" if r["jarak_existing"] is not None else "NULL"
        print(
            f"  {r['ketersediaan_id']:<12} "
            f"{r['padukuhan']:<20} "
            f"{r['kalurahan']:<15} "
            f"{r['latitude']:>10.7f} "
            f"{r['longitude']:>10.7f} "
            f"{r['jarak_computed']:>10.4f} "
            f"{existing:>10}"
        )
    print()

    # Existing non-null check
    existing_non_null = [r for r in rows if r["jarak_existing"] is not None]
    if existing_non_null:
        print(f"WARNING: {len(existing_non_null)} baris sudah memiliki nilai jarak:")
        for r in existing_non_null:
            print(f"  {r['ketersediaan_id']}: existing={r['jarak_existing']:.4f}, "
                  f"computed={r['jarak_computed']:.4f}")
        print()
    else:
        print("OK: Semua 88 baris saat ini NULL — tidak ada data yang akan ditimpa.")
        print()

    print("=" * 90)
    print("PREVIEW COMPLETE — No database changes made.")
    print(f"To write: python scripts/compute_k3_distances.py --write --confirm")
    print("=" * 90)


def write_distances(rows: list[dict[str, Any]], engine) -> int:
    """Write computed distances to database within a transaction.

    Updates only rows where jarak_ke_produksi_km IS NULL.
    Rolls back entirely on any failure.
    Returns number of rows updated.
    """
    update_sql = text("""
        UPDATE ketersediaan_bahan
        SET jarak_ke_produksi_km = :distance
        WHERE ketersediaan_id = :kid
          AND jarak_ke_produksi_km IS NULL
    """)

    with engine.begin() as conn:
        # Double-check: count current NULLs
        null_count = conn.execute(text(
            "SELECT COUNT(*) FROM ketersediaan_bahan WHERE jarak_ke_produksi_km IS NULL"
        )).scalar()

        if null_count != len(rows):
            raise RuntimeError(
                f"Expected {len(rows)} NULL rows but found {null_count}. "
                f"Database state changed since preview. Aborting."
            )

        # Check for existing non-null values that would be skipped
        non_null_count = conn.execute(text(
            "SELECT COUNT(*) FROM ketersediaan_bahan WHERE jarak_ke_produksi_km IS NOT NULL"
        )).scalar()
        if non_null_count > 0:
            raise RuntimeError(
                f"{non_null_count} rows already have non-NULL jarak_ke_produksi_km. "
                f"This script will not overwrite existing values. "
                f"Review and resolve manually before proceeding."
            )

        updated = 0
        for r in rows:
            result = conn.execute(update_sql, {
                "distance": round(r["jarak_computed"], 2),
                "kid": r["ketersediaan_id"],
            })
            updated += result.rowcount

        # Verify: all 88 should now be non-NULL
        remaining_null = conn.execute(text(
            "SELECT COUNT(*) FROM ketersediaan_bahan WHERE jarak_ke_produksi_km IS NULL"
        )).scalar()

        if remaining_null != 0:
            raise RuntimeError(
                f"After update, {remaining_null} rows still NULL. "
                f"Transaction will be rolled back."
            )

        # Verify: total non-null matches expected
        final_count = conn.execute(text(
            "SELECT COUNT(*) FROM ketersediaan_bahan WHERE jarak_ke_produksi_km IS NOT NULL"
        )).scalar()

        if final_count != len(rows):
            raise RuntimeError(
                f"Expected {len(rows)} non-NULL rows after update, got {final_count}. "
                f"Transaction will be rolled back."
            )

        print(f"SUCCESS: {updated} rows updated within transaction.")
        print(f"Verified: {final_count} rows now have jarak_ke_produksi_km.")
        return updated


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compute K3 distances for VINIX7 AHP-SAW (simulation)."
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--preview", action="store_true",
                       help="Show computed distances without writing to database.")
    group.add_argument("--write", action="store_true",
                       help="Write computed distances to database.")
    parser.add_argument("--confirm", action="store_true",
                        help="Required with --write to confirm database modification.")

    args = parser.parse_args()

    if args.write and not args.confirm:
        print("ERROR: --write requires --confirm flag.")
        print("Run with --preview first to review distances.")
        sys.exit(1)

    # Load environment and connect
    load_environment()
    url = database_url()
    assert_local_vinix7(url)
    engine = make_engine(url)

    try:
        with engine.connect() as conn:
            rows = _fetch_kb_padukuhan_coords(conn)

        if len(rows) != 88:
            print(f"ERROR: Expected 88 ketersediaan_bahan rows, found {len(rows)}.")
            sys.exit(1)

        # Compute distances (validates coordinates, checks sanity)
        rows = compute_distances(rows)

        if args.preview:
            print_preview(rows)
        elif args.write:
            print("Writing distances to database...")
            updated = write_distances(rows, engine)
            print(f"\nDone. {updated} rows updated.")
            print("\nREMINDER: Ranking results using these distances are SIMULATIONS.")
            print("Label all outputs accordingly.")

    except Exception as exc:
        print(f"ERROR: {sanitize_error(exc, url)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
