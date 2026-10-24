import json
import unittest

from scripts.vinix_etl import _distance, _parse_quantity, build_datasets


class VinixEtlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_datasets()
        cls.report = cls.result.report
        cls.data = cls.result.datasets

    def test_no_fatal_errors(self):
        self.assertEqual(self.report["fatal_errors"], [])

    def test_sheet_extents(self):
        expected = {
            "Data_produksi_pupuk": (66, 14),
            "Data_Bahan_Organik": (88, 16),
            "Produk_Katalog": (11, 12),
            "Data_Produk_Katalog": (11, 12),
            "Data_Penjualan": (792, 10),
            "Data Wilayah_Kalurahan": (5, 16),
            "Data_Wilayah_Padukuhan": (73, 8),
            "Data_Pertanian": (511, 14),
            "Copy of Data_Penjualan": (792, 19),
            "Copy of Data Pertanian_Dummy": (522, 17),
            "Data Pertanian_real": (14, 14),
            "Copy of Data Wilayah_Kalurahan": (13, 18),
            "Copy of Data Wilayah_Padukuhan": (87, 19),
        }
        actual = {
            item["sheet"]: (item["rows"], item["columns"])
            for item in self.report["sheet_audit"]
        }
        self.assertEqual(actual, expected)

    def test_table_counts(self):
        expected = {
            "kalurahan": 5,
            "padukuhan": 73,
            "data_pertanian": 511,
            "bahan_organik": 17,
            "ketersediaan_bahan": 88,
            "produk": 11,
            "produksi": 66,
            "penjualan": 792,
            "produk_katalog_audit": 11,
            "data_pertanian_real": 14,
        }
        self.assertEqual({name: len(frame) for name, frame in self.data.items()}, expected)
        self.assertEqual(self.report["row_estimates"], {
            "core_total": 1563,
            "catalog_audit": 11,
            "real_agriculture": 14,
            "grand_total": 1588,
        })

    def test_primary_and_natural_keys(self):
        for name, summary in self.report["tables"].items():
            self.assertTrue(summary["primary_key_unique"], name)
            self.assertEqual(summary["natural_key_duplicates"], 0, name)

    def test_foreign_keys_have_no_orphans(self):
        for item in self.report["foreign_keys"]:
            self.assertEqual(item["orphans"], 0, item)

    def test_production_uses_varian_not_total(self):
        rule = self.report["production_rule"]
        self.assertEqual(rule["aggregation_column"], "jumlah_produksi_varian")
        self.assertEqual(rule["sum_varian"], 142638)
        self.assertEqual(rule["sum_total"], 200392)
        self.assertEqual(rule["rows_total_differs"], 36)

    def test_sales_formula_and_period(self):
        sales = self.data["penjualan"]
        self.assertEqual(self.report["sales_consistency"]["formula_mismatches"], 0)
        self.assertEqual(self.report["sales_consistency"]["zero_quantity_rows"], 253)
        self.assertEqual(str(sales["bulan"].min()), "2020-01-01")
        self.assertEqual(str(sales["bulan"].max()), "2025-12-01")

    def test_organic_distances_are_null(self):
        self.assertTrue(self.data["ketersediaan_bahan"]["jarak_ke_produksi_km"].isna().all())
        distance = self.report["organic_distance"]
        self.assertEqual(distance["stored_non_null"], 0)
        self.assertEqual(distance["stored_null"], 88)
        warning = next(w for w in self.report["warnings"] if w["code"] == "organic_distance_unverified")
        self.assertEqual(warning["count"], 88)
        self.assertEqual(warning["datetime_values"], 80)
        self.assertEqual(warning["numeric_values"], 8)

    def test_catalogs_are_separate(self):
        catalogs = self.report["catalogs"]
        self.assertTrue(catalogs["stored_separately"])
        self.assertTrue(catalogs["identical"])
        self.assertEqual(catalogs["main_rows"], 11)
        self.assertEqual(catalogs["audit_rows"], 11)

    def test_synthetic_and_real_agriculture_are_separate(self):
        separation = self.report["synthetic_real"]
        self.assertTrue(separation["separate_tables"])
        self.assertEqual(separation["synthetic_rows"], 511)
        self.assertEqual(separation["real_rows"], 14)
        self.assertEqual(separation["id_overlap"], [])
        self.assertNotIn("padukuhan_id", self.data["data_pertanian_real"].columns)

    def test_real_agriculture_missing_counts(self):
        self.assertEqual(self.report["real_agriculture_missing"], {
            "luas_lahan_ha": 14,
            "jumlah_utp": 9,
            "produksi": 8,
        })

    def test_copy_sheets_are_archive_only(self):
        archive = {item["sheet"]: item for item in self.report["archive_audit"]}
        self.assertEqual(len(archive), 4)
        self.assertEqual(archive["Copy of Data_Penjualan"]["material_differences"], [])
        self.assertEqual(archive["Copy of Data Wilayah_Kalurahan"]["material_differences"], [])
        self.assertEqual(archive["Copy of Data Wilayah_Padukuhan"]["material_differences"], [])
        differences = archive["Copy of Data Pertanian_Dummy"]["material_differences"]
        self.assertEqual({
            (item["key"], item["column"]) for item in differences
        }, {
            ("AGRI-0047", "produksi"),
            ("AGRI-0234", "jumlah_petani"),
            ("AGRI-0308", "luas_lahan_ha"),
        })

    def test_production_status_typo_is_preserved(self):
        self.assertEqual(set(self.data["produksi"]["status_data"]), {"Sintestis"})
        warning = next(w for w in self.report["warnings"] if w["code"] == "production_status_typo")
        self.assertEqual(warning["count"], 66)

    def test_report_does_not_contain_contact_pii(self):
        text = json.dumps(self.report, ensure_ascii=False)
        self.assertNotIn("085.643.596.401", text)
        self.assertNotIn("Agus", text)

    def test_quantity_and_distance_parsing(self):
        self.assertEqual(_parse_quantity("4.103 kg"), (4103.0, "kg"))
        self.assertEqual(_parse_quantity("164L"), (164.0, "L"))
        self.assertEqual(_parse_quantity("32.625 kg"), (32625.0, "kg"))
        self.assertEqual(_distance(1)[0], 1.0)
        self.assertEqual(_distance("2026-07-01")[1], "datetime")


if __name__ == "__main__":
    unittest.main()
