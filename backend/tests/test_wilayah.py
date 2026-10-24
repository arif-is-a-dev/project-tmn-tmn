"""Tests for /api/wilayah endpoints."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient


class TestKalurahanList:
    def test_list_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan")
        assert response.status_code in (200, 503)

    def test_list_200_has_correct_structure(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert "total" in data
        assert "page" in data
        assert "per_page" in data
        assert "items" in data
        assert isinstance(data["items"], list)

    def test_list_pagination_defaults(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert data["page"] == 1
        assert data["per_page"] == 10

    def test_list_invalid_page_rejected(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan?page=0")
        assert response.status_code == 422

    def test_list_per_page_above_max_rejected(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan?per_page=101")
        assert response.status_code == 422

    def test_list_items_have_required_fields(self, client: TestClient):
        response = client.get("/api/wilayah/kalurahan")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table")
        for item in data["items"]:
            assert "kalurahan_id" in item
            assert "kalurahan" in item


class TestPadukuhanList:
    def test_list_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/wilayah/padukuhan")
        assert response.status_code in (200, 503)

    def test_list_200_has_correct_structure(self, client: TestClient):
        response = client.get("/api/wilayah/padukuhan")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert "total" in data
        assert "page" in data
        assert "per_page" in data
        assert "items" in data
        assert isinstance(data["items"], list)

    def test_list_filter_by_kalurahan_id(self, client: TestClient):
        # First get a valid kalurahan_id from the summary endpoint
        summary_resp = client.get("/api/wilayah/summary")
        if summary_resp.status_code != 200:
            pytest.skip("Database unavailable")
        summary = summary_resp.json()
        if summary["total_kalurahan"] == 0:
            pytest.skip("No kalurahan data")

        # Get kalurahan list to find a valid ID
        kal_resp = client.get("/api/wilayah/kalurahan?per_page=1")
        if kal_resp.status_code != 200:
            pytest.skip("Database unavailable")
        kal_data = kal_resp.json()
        if not kal_data["items"]:
            pytest.skip("No kalurahan data")
        kalurahan_id = kal_data["items"][0]["kalurahan_id"]

        # Now filter padukuhan by that kalurahan_id
        response = client.get(f"/api/wilayah/padukuhan?kalurahan_id={kalurahan_id}")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert isinstance(data["items"], list)
        # All returned items should belong to the filtered kalurahan
        for item in data["items"]:
            assert item["kalurahan_id"] == kalurahan_id

    def test_list_items_have_required_fields(self, client: TestClient):
        response = client.get("/api/wilayah/padukuhan")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        if not data["items"]:
            pytest.skip("Empty table")
        for item in data["items"]:
            assert "padukuhan_id" in item
            assert "kalurahan_id" in item
            assert "padukuhan" in item


class TestWilayahSummary:
    def test_summary_returns_200_or_503(self, client: TestClient):
        response = client.get("/api/wilayah/summary")
        assert response.status_code in (200, 503)

    def test_summary_200_has_required_fields(self, client: TestClient):
        response = client.get("/api/wilayah/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert "total_kalurahan" in data
        assert "total_padukuhan" in data
        assert "kalurahan_list" in data
        assert isinstance(data["kalurahan_list"], list)

    def test_summary_counts_are_positive(self, client: TestClient):
        response = client.get("/api/wilayah/summary")
        if response.status_code != 200:
            pytest.skip("Database unavailable")
        data = response.json()
        assert data["total_kalurahan"] > 0
        assert data["total_padukuhan"] > 0
        assert len(data["kalurahan_list"]) == data["total_kalurahan"]
