"""Tests for the /api/forecasts endpoints.

Contract tests (status code, response structure) pass whether or not the
database is reachable.  Data-dependent tests skip when DB is unavailable
so the suite stays green in CI without a live PostgreSQL.

Run:  .venv_backend/Scripts/python.exe -I -m pytest backend/tests/test_forecasts.py -v
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Ensure project root is on path
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

MODEL_PATH = _PROJECT_ROOT / "backend" / "models" / "sales_forecast_pipeline.pkl"
META_PATH = _PROJECT_ROOT / "backend" / "models" / "sales_forecast_metadata.json"


def _model_available() -> bool:
    return MODEL_PATH.exists() and META_PATH.exists()


requires_model = pytest.mark.skipif(
    not _model_available(),
    reason="Model artifacts not found; run train_sales_forecast.py first.",
)


# ── Model availability (no DB needed) ────────────────────────────────────────

class TestModelAvailability:
    """Verify model files exist and are loadable."""

    @requires_model
    def test_pipeline_file_exists(self):
        assert MODEL_PATH.exists()

    @requires_model
    def test_metadata_file_exists(self):
        assert META_PATH.exists()

    @requires_model
    def test_metadata_is_valid_json(self):
        with open(META_PATH, "r", encoding="utf-8") as f:
            meta = json.load(f)
        assert isinstance(meta, dict)
        assert "model_type" in meta
        assert "metrics" in meta

    @requires_model
    def test_pipeline_loads_without_error(self):
        import joblib
        pipeline = joblib.load(MODEL_PATH)
        assert pipeline is not None
        assert hasattr(pipeline, "predict")


# ── Summary endpoint ──────────────────────────────────────────────────────────

class TestForecastSummary:
    """GET /api/forecasts/summary"""

    @requires_model
    def test_summary_returns_200_or_503(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        assert resp.status_code in (200, 503)

    @requires_model
    def test_summary_structure_on_success(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable during this test run")

        data = resp.json()
        assert data["status"] == "ok"
        assert data["error_message"] is None
        assert "total_predictions" in data
        assert "products_count" in data
        assert "forecast_year" in data
        assert "total_predicted_volume" in data
        assert "by_month" in data
        assert "by_product" in data
        assert "model_metadata" in data
        assert "quality_warning" in data

    @requires_model
    def test_summary_has_132_predictions(self, client: TestClient):
        """11 products x 12 months = 132 predictions."""
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert data["total_predictions"] == 132

    @requires_model
    def test_summary_has_11_products(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        assert resp.json()["products_count"] == 11

    @requires_model
    def test_summary_forecast_year(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        assert resp.json()["forecast_year"] == 2026

    @requires_model
    def test_summary_total_volume_positive(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        assert resp.json()["total_predicted_volume"] > 0

    @requires_model
    def test_summary_by_month_has_12_entries(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        assert len(resp.json()["by_month"]) == 12

    @requires_model
    def test_summary_by_month_sorted_chronologically(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        months = [m["bulan"] for m in resp.json()["by_month"]]
        assert months == sorted(months)

    @requires_model
    def test_summary_by_product_has_11_entries(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        assert len(resp.json()["by_product"]) == 11

    @requires_model
    def test_summary_by_product_sorted_descending(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        totals = [p["total"] for p in resp.json()["by_product"]]
        assert totals == sorted(totals, reverse=True)

    @requires_model
    def test_summary_monthly_totals_match_overall(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        monthly_sum = sum(m["total"] for m in data["by_month"])
        assert abs(monthly_sum - data["total_predicted_volume"]) < 0.1

    @requires_model
    def test_summary_product_totals_match_overall(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        product_sum = sum(p["total"] for p in data["by_product"])
        assert abs(product_sum - data["total_predicted_volume"]) < 0.1

    @requires_model
    def test_summary_contains_quality_warning(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        warning = resp.json()["quality_warning"]
        assert "WAPE" in warning
        assert "recursive" in warning.lower()

    @requires_model
    def test_summary_contains_model_metadata(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        meta = resp.json()["model_metadata"]
        assert meta["model_type"] == "ExtraTreesRegressor"
        assert "test_2025" in meta["metrics"]

    @requires_model
    def test_no_negative_predictions_in_by_product(self, client: TestClient):
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        for p in resp.json()["by_product"]:
            assert p["total"] >= 0
            assert p["rata_rata"] >= 0


# ── List endpoint ─────────────────────────────────────────────────────────────

class TestForecastList:
    """GET /api/forecasts"""

    @requires_model
    def test_list_returns_200_or_503(self, client: TestClient):
        resp = client.get("/api/forecasts")
        assert resp.status_code in (200, 503)

    @requires_model
    def test_list_structure_on_success(self, client: TestClient):
        resp = client.get("/api/forecasts")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert "total" in data
        assert "page" in data
        assert "per_page" in data
        assert "items" in data
        assert "model_metadata" in data
        assert "quality_warning" in data
        assert isinstance(data["items"], list)

    @requires_model
    def test_list_default_pagination(self, client: TestClient):
        resp = client.get("/api/forecasts")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert data["page"] == 1
        assert data["per_page"] == 20
        assert len(data["items"]) <= 20
        assert data["total"] == 132

    @requires_model
    def test_list_custom_pagination(self, client: TestClient):
        resp = client.get("/api/forecasts?page=2&per_page=10")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert data["page"] == 2
        assert data["per_page"] == 10
        assert len(data["items"]) <= 10

    @requires_model
    def test_list_item_structure(self, client: TestClient):
        resp = client.get("/api/forecasts?per_page=1")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        item = resp.json()["items"][0]
        assert "bulan" in item
        assert "produk" in item
        assert "prediksi_penjualan" in item
        assert item["bulan"].startswith("2026-")
        assert item["prediksi_penjualan"] >= 0

    @requires_model
    def test_list_filter_by_produk(self, client: TestClient):
        summary_resp = client.get("/api/forecasts/summary")
        if summary_resp.status_code != 200:
            pytest.skip("Database unavailable")
        first_product = summary_resp.json()["by_product"][0]["produk"]
        partial = first_product[:5]

        resp = client.get(f"/api/forecasts?produk={partial}&per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert data["total"] > 0
        for item in data["items"]:
            assert partial.lower() in item["produk"].lower()

    @requires_model
    def test_list_filter_by_bulan(self, client: TestClient):
        resp = client.get("/api/forecasts?bulan=2026-01-01&per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        data = resp.json()
        assert data["total"] == 11
        for item in data["items"]:
            assert item["bulan"] == "2026-01-01"

    @requires_model
    def test_list_all_predictions_non_negative(self, client: TestClient):
        resp = client.get("/api/forecasts?per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        for item in resp.json()["items"]:
            assert item["prediksi_penjualan"] >= 0

    @requires_model
    def test_list_invalid_page_rejected(self, client: TestClient):
        resp = client.get("/api/forecasts?page=0")
        assert resp.status_code == 422


# ── Model unavailable handling ────────────────────────────────────────────────

class TestModelUnavailable:
    """Verify graceful degradation when model files are missing."""

    def test_summary_returns_503_when_model_missing(self, client: TestClient):
        from unittest.mock import patch
        with patch("backend.app.routes.forecasts._MODEL_PATH") as mock_path:
            mock_path.exists.return_value = False
            resp = client.get("/api/forecasts/summary")
            assert resp.status_code == 503

    def test_list_returns_503_when_model_missing(self, client: TestClient):
        from unittest.mock import patch
        with patch("backend.app.routes.forecasts._MODEL_PATH") as mock_path:
            mock_path.exists.return_value = False
            resp = client.get("/api/forecasts")
            assert resp.status_code == 503


# ── No future data leakage ────────────────────────────────────────────────────

class TestDataLeakage:
    """Ensure predictions only cover 2026, not historical or beyond."""

    @requires_model
    def test_all_predictions_are_2026(self, client: TestClient):
        resp = client.get("/api/forecasts?per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        for item in resp.json()["items"]:
            assert item["bulan"].startswith("2026-")

    @requires_model
    def test_all_months_covered(self, client: TestClient):
        resp = client.get("/api/forecasts?per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")
        months = sorted(set(item["bulan"] for item in resp.json()["items"]))
        expected = [f"2026-{m:02d}-01" for m in range(1, 13)]
        assert months == expected


# ── Custom date range forecast ────────────────────────────────────────────────

class TestCustomForecast:
    """POST /api/forecasts/custom — custom date range forecasting."""

    @requires_model
    def test_custom_basic_range(self, client: TestClient):
        """Test the specified range: 2026-03-15 to 2027-08-20 → 18 months × 11 products = 198."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code not in (200, 503):
            pytest.fail(f"Unexpected status {resp.status_code}: {resp.text}")
        if resp.status_code == 503:
            pytest.skip("Database unavailable")

        data = resp.json()
        assert data["status"] == "ok"
        assert data["total_months"] == 18
        assert data["products_count"] == 11
        assert data["total_predictions"] == 198  # 18 × 11
        assert data["start_period"] == "2026-03-01"
        assert data["end_period"] == "2027-08-01"

    @requires_model
    def test_custom_18_periods_per_product(self, client: TestClient):
        """Each product should have exactly 18 monthly predictions."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        from collections import Counter
        product_counts = Counter(item["produk"] for item in data["items"])
        for produk, count in product_counts.items():
            assert count == 18, f"{produk} has {count} predictions, expected 18"

    @requires_model
    def test_custom_correct_months(self, client: TestClient):
        """Verify exact month sequence for 2026-03 to 2027-08."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        months = sorted(set(item["bulan"] for item in data["items"]))
        expected = (
            [f"2026-{m:02d}-01" for m in range(3, 13)] +
            [f"2027-{m:02d}-01" for m in range(1, 9)]
        )
        assert months == expected

    @requires_model
    def test_custom_single_month(self, client: TestClient):
        """Single month range should return 1 period × N products."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-06-01",
            "end_date": "2026-06-30",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        assert data["total_months"] == 1
        assert data["total_predictions"] == 11  # 1 × 11 products
        assert all(item["bulan"] == "2026-06-01" for item in data["items"])

    @requires_model
    def test_custom_cross_year(self, client: TestClient):
        """Cross-year range: Dec 2026 to Feb 2027 = 3 months."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-12-01",
            "end_date": "2027-02-28",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        assert data["total_months"] == 3
        assert data["total_predictions"] == 33  # 3 × 11
        months = sorted(set(item["bulan"] for item in data["items"]))
        assert months == ["2026-12-01", "2027-01-01", "2027-02-01"]

    @requires_model
    def test_custom_end_before_start_rejected(self, client: TestClient):
        """End date before start date should return 400."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2027-06-01",
            "end_date": "2026-01-01",
        })
        assert resp.status_code == 400
        detail = resp.json().get("detail", {})
        assert "error" in detail or "message" in detail

    @requires_model
    def test_custom_invalid_date_rejected(self, client: TestClient):
        """Invalid date format should return 422."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "not-a-date",
            "end_date": "2027-08-20",
        })
        assert resp.status_code == 422

    @requires_model
    def test_custom_missing_dates_rejected(self, client: TestClient):
        """Missing required fields should return 422."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
        })
        assert resp.status_code == 422

    @requires_model
    def test_custom_range_too_long_rejected(self, client: TestClient):
        """Range exceeding 36 months should return 400."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-01-01",
            "end_date": "2030-12-31",  # 60 months
        })
        assert resp.status_code == 400
        detail = resp.json().get("detail", {})
        assert "error" in detail or "message" in detail

    @requires_model
    def test_custom_product_filter(self, client: TestClient):
        """Product filter should limit results to matching products."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-01-01",
            "end_date": "2026-03-31",
            "produk": "pupuk",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable or no matching product")

        data = resp.json()
        assert data["status"] == "ok"
        assert data["products_count"] >= 1
        assert data["total_months"] == 3
        # All items should contain 'pupuk' in product name
        for item in data["items"]:
            assert "pupuk" in item["produk"].lower()

    @requires_model
    def test_custom_product_not_found(self, client: TestClient):
        """Non-existent product filter should return 404."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-01-01",
            "end_date": "2026-03-31",
            "produk": "xyz_nonexistent_product_12345",
        })
        assert resp.status_code == 404

    @requires_model
    def test_custom_predictions_non_negative(self, client: TestClient):
        """All predictions must be non-negative (clamped to 0)."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        for item in resp.json()["items"]:
            assert item["prediksi_penjualan"] >= 0

    @requires_model
    def test_custom_predictions_finite(self, client: TestClient):
        """All predictions must be finite numbers (no NaN or infinity)."""
        import math
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        for item in resp.json()["items"]:
            val = item["prediksi_penjualan"]
            assert math.isfinite(val), f"Non-finite prediction: {val} for {item['produk']} {item['bulan']}"

    @requires_model
    def test_custom_totals_consistent(self, client: TestClient):
        """Monthly totals and product totals should sum to overall total."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        monthly_sum = sum(m["total"] for m in data["by_month"])
        product_sum = sum(p["total"] for p in data["by_product"])
        assert abs(monthly_sum - data["total_predicted_volume"]) < 0.1
        assert abs(product_sum - data["total_predicted_volume"]) < 0.1

    @requires_model
    def test_custom_quality_warning_present(self, client: TestClient):
        """Custom forecast should include quality warning about recursive error."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        warning = resp.json()["quality_warning"]
        assert "recursive" in warning.lower()
        assert len(warning) > 50

    @requires_model
    def test_custom_by_month_sorted(self, client: TestClient):
        """by_month should be sorted chronologically."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-03-15",
            "end_date": "2027-08-20",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        months = [m["bulan"] for m in resp.json()["by_month"]]
        assert months == sorted(months)

    @requires_model
    def test_custom_items_chronological_per_product(self, client: TestClient):
        """Items should be in chronological order per product (recursive order)."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-01-01",
            "end_date": "2026-06-30",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        # Group items by product
        from collections import defaultdict
        by_product = defaultdict(list)
        for item in data["items"]:
            by_product[item["produk"]].append(item["bulan"])

        for produk, months in by_product.items():
            assert months == sorted(months), f"{produk} items not in chronological order"

    @requires_model
    def test_custom_recursive_differs_from_default(self, client: TestClient):
        """Custom range spanning 2026+2027 should produce 2027 predictions that differ
        from standalone 2026 predictions for the same calendar months, because the
        recursive chain feeds 2026 predictions into 2027 lag features.

        Key insight: requesting 2027 alone starts from the same historical window
        as 2026, so Jan values match. But requesting 2026-01 through 2027-12 chains
        predictions, making later months diverge.
        """
        # Get default 2026 predictions
        default_resp = client.get("/api/forecasts?per_page=200")
        if default_resp.status_code != 200:
            pytest.skip("Database unavailable")

        # Get custom range spanning both years (recursive chain)
        custom_resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-01-01",
            "end_date": "2027-12-31",
        })
        if custom_resp.status_code != 200:
            pytest.skip("Database unavailable")

        default_data = default_resp.json()
        custom_data = custom_resp.json()

        assert custom_data["total_predictions"] == 264  # 24 months × 11 products

        # Compare Dec 2026 in default vs Dec 2026 in custom chain
        # They should be identical since both start from the same history
        default_dec = {item["produk"]: item["prediksi_penjualan"]
                       for item in default_data["items"]
                       if item["bulan"] == "2026-12-01"}
        custom_dec = {item["produk"]: item["prediksi_penjualan"]
                      for item in custom_data["items"]
                      if item["bulan"] == "2026-12-01"}

        # Dec 2026 should match between default and custom (same recursive chain)
        for p in default_dec:
            assert abs(default_dec[p] - custom_dec.get(p, -1)) < 0.01, \
                f"Dec 2026 mismatch for {p}: default={default_dec[p]}, custom={custom_dec.get(p)}"

        # Now compare Jan 2027 in custom vs Jan 2026 in default
        # Jan 2027 uses Dec 2026 prediction as lag_1, while Jan 2026 uses Dec 2025 actual
        # These should differ because the lag inputs are different
        custom_jan_2027 = {item["produk"]: item["prediksi_penjualan"]
                           for item in custom_data["items"]
                           if item["bulan"] == "2027-01-01"}
        default_jan_2026 = {item["produk"]: item["prediksi_penjualan"]
                            for item in default_data["items"]
                            if item["bulan"] == "2026-01-01"}

        diffs = sum(1 for p in default_jan_2026
                    if abs(default_jan_2026.get(p, 0) - custom_jan_2027.get(p, 0)) > 0.01)
        assert diffs > 0, "Jan 2027 predictions identical to Jan 2026 — recursive chain may not be working"

    @requires_model
    def test_custom_model_metadata_included(self, client: TestClient):
        """Response should include model metadata."""
        resp = client.post("/api/forecasts/custom", json={
            "start_date": "2026-06-01",
            "end_date": "2026-06-30",
        })
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        meta = resp.json()["model_metadata"]
        assert meta["model_type"] == "ExtraTreesRegressor"
        assert "metrics" in meta

    @requires_model
    def test_old_endpoint_still_works(self, client: TestClient):
        """Default GET /api/forecasts should still return 2026 data unchanged."""
        resp = client.get("/api/forecasts?per_page=200")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        assert data["total"] == 132
        for item in data["items"]:
            assert item["bulan"].startswith("2026-")

    @requires_model
    def test_old_summary_still_works(self, client: TestClient):
        """Default GET /api/forecasts/summary should still return 2026 summary."""
        resp = client.get("/api/forecasts/summary")
        if resp.status_code != 200:
            pytest.skip("Database unavailable")

        data = resp.json()
        assert data["forecast_year"] == 2026
        assert data["total_predictions"] == 132
