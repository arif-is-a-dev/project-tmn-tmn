"""Tests for /api/organic-materials endpoints.

These tests run against the live database via TestClient.
They verify both structural correctness and business logic of the
AHP-SAW ranking system with K3 (synthetic Haversine distances) filled.

Tests that depend on specific data values use guards (skip if DB unavailable)
rather than hard-failing, so the suite remains runnable in CI without a DB.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient


def _skip_if_unavailable(response) -> None:
    """Skip the test if the database is not reachable."""
    if response.status_code == 503:
        pytest.skip("Database unavailable")


class TestOrganicList:
    def test_list_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/organic-materials")
        assert response.status_code in (200, 503)

    def test_list_200_has_correct_structure(self, client: TestClient):
        response = client.get("/api/organic-materials")
        _skip_if_unavailable(response)
        data = response.json()
        assert "total" in data
        assert "page" in data
        assert "per_page" in data
        assert "items" in data
        assert isinstance(data["items"], list)

    def test_list_pagination_defaults(self, client: TestClient):
        response = client.get("/api/organic-materials")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["page"] == 1
        assert data["per_page"] == 10

    def test_list_invalid_page_rejected(self, client: TestClient):
        response = client.get("/api/organic-materials?page=0")
        assert response.status_code == 422

    def test_list_per_page_above_max_rejected(self, client: TestClient):
        response = client.get("/api/organic-materials?per_page=101")
        assert response.status_code == 422

    def test_list_items_have_required_fields(self, client: TestClient):
        response = client.get("/api/organic-materials")
        _skip_if_unavailable(response)
        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table")
        for item in data["items"]:
            assert "bahan" in item
            assert "availability" in item
            b = item["bahan"]
            assert "bahan_id" in b
            assert "jenis_bahan_organik" in b
            assert "kategori_bahan" in b
            a = item["availability"]
            assert "total_records" in a
            assert "total_quantity" in a

    def test_list_total_matches_expected(self, client: TestClient):
        """Dataset has 17 organic materials."""
        response = client.get("/api/organic-materials?per_page=100")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["total"] == 17


class TestOrganicSummary:
    def test_summary_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/organic-materials/summary")
        assert response.status_code in (200, 503)

    def test_summary_200_has_required_fields(self, client: TestClient):
        response = client.get("/api/organic-materials/summary")
        _skip_if_unavailable(response)
        data = response.json()
        assert "total_materials" in data
        assert "total_availability_records" in data
        assert "materials_with_availability" in data
        assert "criteria_complete" in data
        assert "missing_criteria" in data
        assert isinstance(data["missing_criteria"], list)

    def test_summary_criteria_complete(self, client: TestClient):
        """All 4 criteria (K1-K4) should be complete with K3 distances filled."""
        response = client.get("/api/organic-materials/summary")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["criteria_complete"] is True
        assert data["missing_criteria"] == []

    def test_summary_counts(self, client: TestClient):
        """Verify expected dataset counts."""
        response = client.get("/api/organic-materials/summary")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["total_materials"] == 17
        assert data["total_availability_records"] == 88
        assert data["materials_with_availability"] == 17


class TestOrganicCriteriaStatus:
    def test_criteria_status_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/organic-materials/criteria-status")
        assert response.status_code in (200, 503)

    def test_criteria_status_has_four_criteria(self, client: TestClient):
        response = client.get("/api/organic-materials/criteria-status")
        _skip_if_unavailable(response)
        data = response.json()
        assert "criteria" in data
        assert len(data["criteria"]) == 4
        codes = [c["code"] for c in data["criteria"]]
        assert codes == ["K1", "K2", "K3", "K4"]

    def test_all_criteria_complete(self, client: TestClient):
        """All criteria including K3 should be complete after distance fill."""
        response = client.get("/api/organic-materials/criteria-status")
        _skip_if_unavailable(response)
        data = response.json()
        for c in data["criteria"]:
            assert c["complete"] is True, f"{c['code']} should be complete"

    def test_k3_is_cost_type(self, client: TestClient):
        """K3 must remain a Cost criterion regardless of data state."""
        response = client.get("/api/organic-materials/criteria-status")
        _skip_if_unavailable(response)
        data = response.json()
        k3 = next(c for c in data["criteria"] if c["code"] == "K3")
        assert k3["type"] == "Cost"
        assert k3["name"] == "Jarak ke lokasi produksi"


class TestOrganicRanking:
    def test_ranking_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/organic-materials/ranking")
        assert response.status_code in (200, 503)

    def test_ranking_status_ok(self, client: TestClient):
        """Ranking should return status='ok' when all criteria are complete."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["status"] == "ok"
        assert data["blocked_reason"] is None
        assert data["missing_criteria"] == []

    def test_ranking_returns_all_materials(self, client: TestClient):
        """All 17 bahan organik should appear in ranking."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        assert len(data["items"]) == 17

    def test_ranking_weights_are_simulation(self, client: TestClient):
        """Weights must always be labeled as simulation."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["weights_are_simulation"] is True
        assert data["ahp_weights"] is not None
        wsum = sum(data["ahp_weights"].values())
        assert abs(wsum - 1.0) < 1e-4

    def test_ranking_consistency_ratio_valid(self, client: TestClient):
        """CR must be below 0.10 threshold."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        assert data["consistency_ratio"] is not None
        assert data["consistency_ratio"] < 0.10

    def test_ranking_scores_descending(self, client: TestClient):
        """Items must be sorted by skor_akhir in non-increasing order."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        items = data["items"]
        for i in range(len(items) - 1):
            assert items[i]["skor_akhir"] >= items[i + 1]["skor_akhir"]

    def test_ranking_competition_ranking(self, client: TestClient):
        """Tied scores share the same rank; next rank skips ahead."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        items = data["items"]
        for i in range(len(items) - 1):
            if abs(items[i]["skor_akhir"] - items[i + 1]["skor_akhir"]) < 1e-5:
                assert items[i]["peringkat"] == items[i + 1]["peringkat"]
            else:
                assert items[i]["peringkat"] < items[i + 1]["peringkat"]

    def test_ranking_methodological_note_present(self, client: TestClient):
        """Response must include methodological note about simulation."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        note = data.get("methodological_note")
        assert note is not None, "methodological_note must be present"
        assert "Simulasi" in note or "simulasi" in note
        assert "centroid" in note.lower()
        assert "Haversine" in note

    def test_ranking_item_fields(self, client: TestClient):
        """Each ranking item must have required fields."""
        response = client.get("/api/organic-materials/ranking")
        _skip_if_unavailable(response)
        data = response.json()
        for item in data["items"]:
            assert "peringkat" in item
            assert "bahan_id" in item
            assert "jenis_bahan_organik" in item
            assert "kategori_bahan" in item
            assert "skor_akhir" in item
            assert "jumlah_ketersediaan" in item
            assert "skor_kontinuitas" in item
            assert "skor_kemudahan" in item
            assert isinstance(item["peringkat"], int)
            assert isinstance(item["skor_akhir"], float)
            assert item["skor_akhir"] >= 0


class TestOrganicRankingBlockedScenario:
    """Verify ranking blocks correctly when criteria are incomplete.

    These tests use dependency override to simulate NULL K3 data WITHOUT
    modifying the production database. They verify the blocking mechanism
    still works correctly.
    """

    def test_ranking_blocks_when_k3_null(self, client: TestClient):
        """When K3 data is NULL, ranking must return status='blocked'."""
        from unittest.mock import patch
        from backend.app.routes.organic import _check_criteria_completeness

        # Override completeness check to simulate K3 missing
        def mock_check(session):
            return False, ["K3"]

        with patch(
            "backend.app.routes.organic._check_criteria_completeness",
            side_effect=mock_check,
        ):
            response = client.get("/api/organic-materials/ranking")
            _skip_if_unavailable(response)
            data = response.json()
            assert data["status"] == "blocked"
            assert "K3" in data["missing_criteria"]
            assert data["blocked_reason"] is not None
            assert len(data["items"]) == 0
            assert data["ahp_weights"] is None

    def test_ranking_no_weights_when_blocked(self, client: TestClient):
        """When blocked, ahp_weights must be null (not fabricated)."""
        from unittest.mock import patch

        def mock_check(session):
            return False, ["K3"]

        with patch(
            "backend.app.routes.organic._check_criteria_completeness",
            side_effect=mock_check,
        ):
            response = client.get("/api/organic-materials/ranking")
            _skip_if_unavailable(response)
            data = response.json()
            assert data["status"] == "blocked"
            assert data["ahp_weights"] is None
            assert data["weights_are_simulation"] is True
