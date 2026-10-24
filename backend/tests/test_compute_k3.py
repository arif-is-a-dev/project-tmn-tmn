"""Unit tests for scripts/compute_k3_distances.py.

Tests the pure computation logic WITHOUT database access.
Database integration (preview/write) is tested manually via --preview mode.

Covers:
  1. compute_distances with valid synthetic data
  2. Validation: missing coordinates raise ValueError
  3. Validation: coincident coordinates raise ValueError
  4. Validation: distance exceeding sanity limit raises ValueError
  5. No negative distances produced
  6. Correct number of rows processed
  7. Reference point constants are consistent
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Ensure project root on path
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

from backend.app.geo import haversine
from scripts.compute_k3_distances import (
    MAX_REASONABLE_KM,
    PRODUCTION_REF_LAT,
    PRODUCTION_REF_LON,
    compute_distances,
)


def _make_row(kid: str, lat: float | None, lon: float | None,
              existing: float | None = None) -> dict:
    """Create a minimal row dict matching _fetch_kb_padukuhan_coords output."""
    return {
        "ketersediaan_id": kid,
        "bahan_id": "BHN-001",
        "padukuhan_id": f"PAD-{kid[-3:]}",
        "padukuhan": f"TestPad_{kid}",
        "kalurahan": "TestKal",
        "latitude": lat,
        "longitude": lon,
        "jarak_existing": existing,
    }


class TestComputeDistancesValid:
    """compute_distances produces correct results for valid input."""

    def test_returns_same_number_of_rows(self):
        rows = [
            _make_row("KB-001", -7.6500, 110.4500),
            _make_row("KB-002", -7.6600, 110.4600),
            _make_row("KB-003", -7.6400, 110.4400),
        ]
        result = compute_distances(rows)
        assert len(result) == 3

    def test_adds_jarak_computed_field(self):
        rows = [_make_row("KB-001", -7.6500, 110.4500)]
        result = compute_distances(rows)
        assert "jarak_computed" in result[0]

    def test_distance_matches_haversine_directly(self):
        lat, lon = -7.6500, 110.4500
        rows = [_make_row("KB-001", lat, lon)]
        result = compute_distances(rows)
        expected = haversine(lat, lon, PRODUCTION_REF_LAT, PRODUCTION_REF_LON)
        assert result[0]["jarak_computed"] == expected

    def test_all_distances_positive(self):
        rows = [
            _make_row(f"KB-{i:03d}", -7.6 + i * 0.001, 110.45 + i * 0.001)
            for i in range(10)
        ]
        result = compute_distances(rows)
        for r in result:
            assert r["jarak_computed"] > 0, f"{r['ketersediaan_id']} has non-positive distance"

    def test_no_distance_exceeds_sanity_limit(self):
        # All within Cangkringan area — should be well under 20 km
        rows = [
            _make_row("KB-001", -7.6500, 110.4500),
            _make_row("KB-002", -7.6800, 110.4700),
            _make_row("KB-003", -7.5900, 110.4300),
        ]
        result = compute_distances(rows)
        for r in result:
            assert r["jarak_computed"] <= MAX_REASONABLE_KM

    def test_preserves_original_fields(self):
        rows = [_make_row("KB-001", -7.6500, 110.4500, existing=5.0)]
        result = compute_distances(rows)
        assert result[0]["ketersediaan_id"] == "KB-001"
        assert result[0]["jarak_existing"] == 5.0
        assert result[0]["latitude"] == -7.6500


class TestComputeDistancesValidation:
    """compute_distances rejects invalid input with clear errors."""

    def test_missing_latitude_raises(self):
        rows = [_make_row("KB-001", None, 110.4500)]
        with pytest.raises(ValueError, match="tidak memiliki koordinat"):
            compute_distances(rows)

    def test_missing_longitude_raises(self):
        rows = [_make_row("KB-001", -7.6500, None)]
        with pytest.raises(ValueError, match="tidak memiliki koordinat"):
            compute_distances(rows)

    def test_both_coordinates_none_raises(self):
        rows = [_make_row("KB-001", None, None)]
        with pytest.raises(ValueError, match="tidak memiliki koordinat"):
            compute_distances(rows)

    def test_coincident_with_reference_raises(self):
        """A padukuhan at exactly the reference point would produce distance=0,
        which is invalid for a cost criterion in SAW."""
        rows = [_make_row("KB-001", PRODUCTION_REF_LAT, PRODUCTION_REF_LON)]
        with pytest.raises(ValueError, match="koordinat identik"):
            compute_distances(rows)

    def test_unreasonable_distance_raises(self):
        """Point far outside Cangkringan should exceed sanity limit."""
        # Jakarta is ~500 km away
        rows = [_make_row("KB-001", -6.2088, 106.8456)]
        with pytest.raises(ValueError, match="melebihi batas kewajaran"):
            compute_distances(rows)

    def test_error_message_includes_padukuhan_id(self):
        rows = [_make_row("KB-001", None, 110.4500)]
        with pytest.raises(ValueError, match="PAD-001"):
            compute_distances(rows)


class TestReferencePointConstants:
    """Verify reference point constants are self-consistent."""

    def test_latitude_in_valid_range(self):
        assert -90 <= PRODUCTION_REF_LAT <= 90

    def test_longitude_in_valid_range(self):
        assert -180 <= PRODUCTION_REF_LON <= 180

    def test_reference_point_is_in_cangkringan_area(self):
        """Centroid should fall within the bounding box of source padukuhan."""
        # Known bounding box from audit
        assert -7.685 <= PRODUCTION_REF_LAT <= -7.573
        assert 110.426 <= PRODUCTION_REF_LON <= 110.473

    def test_max_reasonable_km_is_positive(self):
        assert MAX_REASONABLE_KM > 0

    def test_max_reasonable_km_appropriate_for_kecamatan(self):
        """20 km is generous for a single kecamatan; anything larger is suspicious."""
        assert MAX_REASONABLE_KM <= 50


class TestEdgeCases:
    """Edge cases in computation."""

    def test_single_row(self):
        rows = [_make_row("KB-001", -7.6500, 110.4500)]
        result = compute_distances(rows)
        assert len(result) == 1
        assert result[0]["jarak_computed"] > 0

    def test_empty_list(self):
        result = compute_distances([])
        assert result == []

    def test_existing_non_null_preserved(self):
        """compute_distances adds jarak_computed regardless of existing value."""
        rows = [_make_row("KB-001", -7.6500, 110.4500, existing=3.5)]
        result = compute_distances(rows)
        assert result[0]["jarak_existing"] == 3.5
        assert result[0]["jarak_computed"] != 3.5  # computed from Haversine

    def test_multiple_rows_different_distances(self):
        """Different padukuhan should produce different distances (unless symmetric)."""
        rows = [
            _make_row("KB-001", -7.6500, 110.4500),
            _make_row("KB-002", -7.6800, 110.4700),
            _make_row("KB-003", -7.6000, 110.4400),
        ]
        result = compute_distances(rows)
        distances = [r["jarak_computed"] for r in result]
        # At least some should differ
        assert len(set(distances)) > 1
