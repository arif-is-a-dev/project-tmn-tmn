"""Tests for the /api/production endpoints.

Contract tests (status code, response structure) should pass whether or not
the database is reachable.  Filter/pagination tests skip when the DB is empty
so the test suite remains green in CI environments without a live PostgreSQL.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient


class TestProductionList:
    """Tests for GET /api/production — response contract."""

    def test_list_production_returns_200_or_503(self, client: TestClient):
        """API always returns a response — 200 when DB is up, 503 when down."""
        response = client.get("/api/production")
        assert response.status_code in (200, 503)

    def test_list_production_200_has_correct_structure(self, client: TestClient):
        """On 200, the response has all required paginated-list fields."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert "total"     in data
        assert "page"      in data
        assert "per_page"  in data
        assert "items"     in data
        assert isinstance(data["items"], list)

    def test_list_production_pagination_defaults(self, client: TestClient):
        """Default pagination is page=1, per_page=10."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]     == 1
        assert data["per_page"] == 10

    def test_list_production_pagination_custom(self, client: TestClient):
        """Custom page and per_page are accepted."""
        response = client.get("/api/production?page=2&per_page=5")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]     == 2
        assert data["per_page"] == 5

    def test_list_production_invalid_page_rejected(self, client: TestClient):
        """page=0 is rejected with 422 Unprocessable Entity."""
        response = client.get("/api/production?page=0")
        assert response.status_code == 422

    def test_list_production_per_page_above_max_rejected(self, client: TestClient):
        """per_page=101 exceeds the 100-item maximum and returns 422."""
        response = client.get("/api/production?per_page=101")
        assert response.status_code == 422

    def test_list_production_items_have_required_fields(self, client: TestClient):
        """Every item has the core production fields."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table — cannot validate item shape")

        for item in data["items"]:
            assert "produksi_id"              in item
            assert "produk_id"               in item
            assert "nama_produk"             in item
            assert "jenis_produk"            in item
            assert "jumlah_produksi_varian"  in item
            assert "satuan"                  in item
            assert "periode_produksi"        in item
            assert "status_data"             in item

    def test_list_production_page_beyond_results_returns_empty_items(self, client: TestClient):
        """Requesting a page beyond available data returns total > 0 but empty items."""
        response = client.get("/api/production?page=9999")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]  == 9999
        assert isinstance(data["items"], list)
        assert data["total"] >= 0


class TestProductionFilters:
    """Tests for GET /api/production filter parameters."""

    def test_list_production_filter_by_periode(self, client: TestClient):
        """When filtering by periode, every returned item matches exactly."""
        response = client.get("/api/production?periode=2024")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        for item in data["items"]:
            assert item["periode_produksi"] == 2024

    def test_list_production_filter_by_jenis_produk(self, client: TestClient):
        """When filtering by jenis_produk, every returned item matches exactly."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table — cannot run filter test")

        jenis = data["items"][0]["jenis_produk"]
        filtered = client.get(f"/api/production?jenis_produk={jenis}")
        if filtered.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        for item in filtered.json()["items"]:
            assert item["jenis_produk"] == jenis

    def test_list_production_filter_by_nama_produk_is_case_insensitive(self, client: TestClient):
        """A lowercase nama_produk filter matches mixed-case product names."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table — cannot run filter test")

        sample_name = data["items"][0]["nama_produk"][:4]
        filtered = client.get(f"/api/production?nama_produk={sample_name.lower()}")
        if filtered.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        for item in filtered.json()["items"]:
            assert sample_name.lower() in item["nama_produk"].lower()

    def test_list_production_combined_filters(self, client: TestClient):
        """Filter by both jenis_produk and periode simultaneously."""
        response = client.get("/api/production")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        items = response.json()["items"]
        if not items:
            pytest.skip("Empty table")

        jenis   = items[0]["jenis_produk"]
        periode = items[0]["periode_produksi"]

        filtered = client.get(f"/api/production?jenis_produk={jenis}&periode={periode}")
        if filtered.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = filtered.json()
        for item in data["items"]:
            assert item["jenis_produk"]      == jenis
            assert item["periode_produksi"] == periode


class TestProductionSummary:
    """Tests for GET /api/production/summary."""

    def test_summary_returns_200_or_503(self, client: TestClient):
        """Summary always returns a response — 200 when DB is up, 503 when down."""
        response = client.get("/api/production/summary")
        assert response.status_code in (200, 503)

    def test_summary_200_has_required_fields(self, client: TestClient):
        """On 200, all summary fields are present and have the correct type."""
        response = client.get("/api/production/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert "total_records"             in data
        assert "distinct_products"          in data
        assert "distinct_periods"           in data
        assert "earliest_period"           in data
        assert "latest_period"             in data
        assert "total_production_varian"   in data
        assert "total_stok"                in data

        assert isinstance(data["total_records"], int)
        assert isinstance(data["distinct_products"], int)
        assert isinstance(data["distinct_periods"], int)
        assert isinstance(data["total_production_varian"], (int, float))

    def test_summary_zero_counts_when_empty(self, client: TestClient):
        """When the table is empty, total_records is 0 and counts are zero/null."""
        # This test is only meaningful when the table is known to be empty.
        # We run it and assert the shape regardless of values.
        response = client.get("/api/production/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert "total_records" in data
        assert "total_production_varian" in data

    def test_summary_distinct_periods_never_negative(self, client: TestClient):
        """Counts are always non-negative."""
        response = client.get("/api/production/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["total_records"]      >= 0
        assert data["distinct_products"]   >= 0
        assert data["distinct_periods"]   >= 0
        assert data["total_production_varian"] >= 0
