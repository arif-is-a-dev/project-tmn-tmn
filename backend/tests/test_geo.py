"""Unit tests for backend.app.geo — Haversine distance computation.

All tests use SYNTHETIC data only — no database, no network.
Verifies:
  1. Identical coordinates → distance = 0
  2. Known reference pairs with verified distances
  3. Coordinate range validation (latitude [-90,90], longitude [-180,180])
  4. NULL / None input handling → returns None
  5. Symmetry (A→B == B→A)
  6. Edge cases (poles, equator, antipodal points)
  7. Precision at short distances (<1 km)
"""

from __future__ import annotations

import math

import pytest

from backend.app.geo import EARTH_RADIUS_KM, haversine


class TestIdenticalCoordinates:
    """Distance between identical points must be exactly 0."""

    def test_same_point_zero_distance(self):
        assert haversine(-7.6588, 110.4563, -7.6588, 110.4563) == 0.0

    def test_origin_zero_distance(self):
        assert haversine(0.0, 0.0, 0.0, 0.0) == 0.0

    def test_negative_coords_zero_distance(self):
        assert haversine(-33.8688, 151.2093, -33.8688, 151.2093) == 0.0

    def test_pole_zero_distance(self):
        assert haversine(90.0, 0.0, 90.0, 0.0) == 0.0

    def test_antimeridian_zero_distance(self):
        assert haversine(0.0, 180.0, 0.0, 180.0) == 0.0


class TestKnownDistances:
    """Verify against independently computed reference distances.

    Reference values computed via geopy.distance.geodesic (WGS-84 ellipsoid)
    and cross-checked with online Haversine calculators. Tolerance accounts
    for spherical vs ellipsoidal model difference (~0.3% at these scales).
    """

    def test_yogyakarta_to_semarang(self):
        """Yogyakarta (-7.7972, 110.3688) → Semarang (-6.9667, 110.4167).
        Geodesic ≈ 92.3 km; Haversine sphere ≈ 92.1 km."""
        d = haversine(-7.7972, 110.3688, -6.9667, 110.4167)
        assert d is not None
        assert abs(d - 92.1) < 1.0  # within 1 km tolerance

    def test_cangkringan_centroid_to_argomulyo(self):
        """Cangkringan centroid (-7.6588, 110.4563) → Argomulyo (-7.6694, 110.4389).
        Short intra-kecamatan distance ≈ 2.1 km."""
        d = haversine(-7.6588, 110.4563, -7.6694, 110.4389)
        assert d is not None
        assert abs(d - 2.1) < 0.3  # within 300m tolerance

    def test_jakarta_to_bandung(self):
        """Jakarta (-6.2088, 106.8456) → Bandung (-6.9175, 107.6191).
        Well-known distance ≈ 117 km (Haversine sphere)."""
        d = haversine(-6.2088, 106.8456, -6.9175, 107.6191)
        assert d is not None
        assert abs(d - 117.0) < 2.0

    def test_london_to_paris(self):
        """London (51.5074, -0.1278) → Paris (48.8566, 2.3522).
        Classic reference: ≈ 343 km (Haversine sphere)."""
        d = haversine(51.5074, -0.1278, 48.8566, 2.3522)
        assert d is not None
        assert abs(d - 343.0) < 3.0

    def test_short_distance_under_1km(self):
        """Two points ~500m apart in Cangkringan area.
        Verifies precision at sub-kilometer scale."""
        # Approximately 500m north
        d = haversine(-7.6588, 110.4563, -7.6543, 110.4563)
        assert d is not None
        assert 0.4 < d < 0.6  # should be ~0.5 km


class TestCoordinateValidation:
    """Invalid coordinates must raise ValueError, not return wrong results."""

    def test_lat1_too_high(self):
        with pytest.raises(ValueError, match="lat1"):
            haversine(91.0, 0.0, 0.0, 0.0)

    def test_lat1_too_low(self):
        with pytest.raises(ValueError, match="lat1"):
            haversine(-91.0, 0.0, 0.0, 0.0)

    def test_lat2_too_high(self):
        with pytest.raises(ValueError, match="lat2"):
            haversine(0.0, 0.0, 90.1, 0.0)

    def test_lat2_too_low(self):
        with pytest.raises(ValueError, match="lat2"):
            haversine(0.0, 0.0, -90.1, 0.0)

    def test_lon1_too_high(self):
        with pytest.raises(ValueError, match="lon1"):
            haversine(0.0, 181.0, 0.0, 0.0)

    def test_lon1_too_low(self):
        with pytest.raises(ValueError, match="lon1"):
            haversine(0.0, -181.0, 0.0, 0.0)

    def test_lon2_too_high(self):
        with pytest.raises(ValueError, match="lon2"):
            haversine(0.0, 0.0, 0.0, 180.1)

    def test_lon2_too_low(self):
        with pytest.raises(ValueError, match="lon2"):
            haversine(0.0, 0.0, 0.0, -180.1)

    def test_boundary_values_accepted(self):
        """Exact boundary values (-90, 90, -180, 180) must NOT raise."""
        assert haversine(-90.0, -180.0, 90.0, 180.0) is not None
        assert haversine(90.0, 180.0, -90.0, -180.0) is not None
        assert haversine(0.0, 0.0, 0.0, 0.0) is not None


class TestNullHandling:
    """None inputs must return None, never raise or return a number."""

    def test_all_none(self):
        assert haversine(None, None, None, None) is None

    def test_lat1_none(self):
        assert haversine(None, 110.0, -7.0, 110.0) is None

    def test_lon1_none(self):
        assert haversine(-7.0, None, -7.0, 110.0) is None

    def test_lat2_none(self):
        assert haversine(-7.0, 110.0, None, 110.0) is None

    def test_lon2_none(self):
        assert haversine(-7.0, 110.0, -7.0, None) is None

    def test_mixed_none_and_valid(self):
        assert haversine(-7.0, None, None, 110.0) is None

    def test_none_does_not_raise(self):
        """Ensure None never triggers ValueError from range check."""
        result = haversine(None, 0.0, 0.0, 0.0)
        assert result is None


class TestSymmetry:
    """Distance must be symmetric: d(A,B) == d(B,A)."""

    def test_symmetry_local(self):
        d_ab = haversine(-7.6588, 110.4563, -7.6694, 110.4389)
        d_ba = haversine(-7.6694, 110.4389, -7.6588, 110.4563)
        assert d_ab == d_ba

    def test_symmetry_long_distance(self):
        d_ab = haversine(-6.2088, 106.8456, 51.5074, -0.1278)
        d_ba = haversine(51.5074, -0.1278, -6.2088, 106.8456)
        assert d_ab == d_ba

    def test_symmetry_across_equator(self):
        d_ab = haversine(-7.0, 110.0, 7.0, 110.0)
        d_ba = haversine(7.0, 110.0, -7.0, 110.0)
        assert d_ab == d_ba


class TestEdgeCases:
    """Geographic edge cases that can expose formula bugs."""

    def test_north_pole_to_south_pole(self):
        """Half circumference ≈ 20015 km."""
        d = haversine(90.0, 0.0, -90.0, 0.0)
        assert d is not None
        expected = math.pi * EARTH_RADIUS_KM  # πR ≈ 20015
        assert abs(d - expected) < 1.0

    def test_antipodal_equator(self):
        """Opposite sides of equator ≈ 20015 km."""
        d = haversine(0.0, 0.0, 0.0, 180.0)
        assert d is not None
        expected = math.pi * EARTH_RADIUS_KM
        assert abs(d - expected) < 1.0

    def test_crossing_antimeridian(self):
        """Points on either side of the ±180° meridian.
        lon1=179, lon2=-179 should be ~222 km apart (not ~39800)."""
        d = haversine(0.0, 179.0, 0.0, -179.0)
        assert d is not None
        # 2 degrees of longitude at equator ≈ 222 km
        assert abs(d - 222.0) < 5.0

    def test_very_small_distance(self):
        """Two points ~11m apart (0.0001° latitude)."""
        d = haversine(-7.6588, 110.4563, -7.6589, 110.4563)
        assert d is not None
        assert 0.005 < d < 0.020  # ~11m = 0.011 km

    def test_return_type_is_float_or_none(self):
        d = haversine(-7.6588, 110.4563, -7.6694, 110.4389)
        assert isinstance(d, float)
        assert haversine(None, None, None, None) is None

    def test_result_precision_four_decimals(self):
        """Result should be rounded to 4 decimal places."""
        d = haversine(-7.6588, 110.4563, -7.6694, 110.4389)
        assert d is not None
        # Check it has at most 4 decimal places
        assert d == round(d, 4)
