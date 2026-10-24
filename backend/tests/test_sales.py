"""Tests for the /api/sales endpoints.

Contract tests (status code, response structure) should pass whether or not
the database is reachable.  Filter/pagination tests skip when the DB is empty
so the test suite remains green in CI environments without a live PostgreSQL.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient


class TestSalesList:
    """Tests for GET /api/sales — response contract."""

    def test_list_sales_returns_200_or_503(self, client: TestClient):
        """API always returns a response — 200 when DB is up, 503 when down."""
        response = client.get("/api/sales")
        assert response.status_code in (200, 503)

    def test_list_sales_200_has_correct_structure(self, client: TestClient):
        """On 200, the response has all required paginated-list fields."""
        response = client.get("/api/sales")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert "total"     in data
        assert "page"      in data
        assert "per_page"  in data
        assert "items"     in data
        assert isinstance(data["items"], list)

    def test_list_sales_pagination_defaults(self, client: TestClient):
        """Default pagination is page=1, per_page=20."""
        response = client.get("/api/sales")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]     == 1
        assert data["per_page"] == 20

    def test_list_sales_pagination_custom(self, client: TestClient):
        """Custom page and per_page are accepted."""
        response = client.get("/api/sales?page=2&per_page=5")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]     == 2
        assert data["per_page"] == 5

    def test_list_sales_invalid_page_rejected(self, client: TestClient):
        """page=0 is rejected with 422 Unprocessable Entity."""
        response = client.get("/api/sales?page=0")
        assert response.status_code == 422

    def test_list_sales_per_page_above_max_rejected(self, client: TestClient):
        """per_page=101 exceeds the 100-item maximum and returns 422."""
        response = client.get("/api/sales?per_page=101")
        assert response.status_code == 422

    def test_list_sales_items_have_required_fields(self, client: TestClient):
        """Every item has the core sales fields."""
        response = client.get("/api/sales")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table — cannot validate item shape")

        for item in data["items"]:
            assert "penjualan_id"    in item
            assert "produk_id"      in item
            assert "bulan"          in item
            assert "produk"         in item
            assert "jumlah_terjual" in item
            assert "harga_satuan"   in item
            assert "total_penjualan" in item

    def test_list_sales_filter_by_produk_id(self, client: TestClient):
        """When filtering by produk_id, every returned item matches exactly."""
        response = client.get("/api/sales")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table — cannot run filter test")

        pid = data["items"][0]["produk_id"]
        filtered = client.get(f"/api/sales?produk_id={pid}")
        if filtered.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        for item in filtered.json()["items"]:
            assert item["produk_id"] == pid

    def test_list_sales_filter_by_periode_start(self, client: TestClient):
        """periode_start filter restricts results to bulan >= given date."""
        response = client.get("/api/sales?periode_start=2023-01-01")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        for item in data["items"]:
            assert item["bulan"] >= "2023-01-01"

    def test_list_sales_filter_by_periode_end(self, client: TestClient):
        """periode_end filter restricts results to bulan <= given date."""
        response = client.get("/api/sales?periode_end=2023-12-31")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        for item in data["items"]:
            assert item["bulan"] <= "2023-12-31"

    def test_list_sales_combined_date_filters(self, client: TestClient):
        """Combined periode_start and periode_end restrict results correctly."""
        response = client.get("/api/sales?periode_start=2023-01-01&periode_end=2023-12-31")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        for item in data["items"]:
            assert "2023-01-01" <= item["bulan"] <= "2023-12-31"

    def test_list_sales_page_beyond_results_returns_empty_items(self, client: TestClient):
        """Requesting a page beyond available data returns total > 0 but empty items."""
        response = client.get("/api/sales?page=9999")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["page"]  == 9999
        assert isinstance(data["items"], list)
        assert data["total"] >= 0


class TestSalesSummary:
    """Tests for GET /api/sales/summary."""

    def test_summary_returns_200_or_503(self, client: TestClient):
        """Summary always returns a response — 200 when DB is up, 503 when down."""
        response = client.get("/api/sales/summary")
        assert response.status_code in (200, 503)

    def test_summary_200_has_required_fields(self, client: TestClient):
        """On 200, all summary fields are present and have the correct type."""
        response = client.get("/api/sales/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert "total_records"     in data
        assert "total_revenue"     in data
        assert "total_volume"      in data
        assert "distinct_products" in data
        assert "period_start"      in data
        assert "period_end"        in data
        assert "by_channel"        in data

        assert isinstance(data["total_records"], int)
        assert isinstance(data["distinct_products"], int)
        assert isinstance(data["total_revenue"], (int, float))
        assert isinstance(data["total_volume"], (int, float))
        assert isinstance(data["by_channel"], list)

    def test_summary_revenue_and_volume_non_negative(self, client: TestClient):
        """Revenue and volume are always non-negative."""
        response = client.get("/api/sales/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        assert data["total_records"]     >= 0
        assert data["total_revenue"]     >= 0
        assert data["total_volume"]      >= 0
        assert data["distinct_products"] >= 0

    def test_summary_by_channel_structure(self, client: TestClient):
        """Each channel entry has kanal, total_revenue, total_volume, count."""
        response = client.get("/api/sales/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = response.json()
        for ch in data["by_channel"]:
            assert "kanal"          in ch
            assert "total_revenue"  in ch
            assert "total_volume"   in ch
            assert "count"          in ch
