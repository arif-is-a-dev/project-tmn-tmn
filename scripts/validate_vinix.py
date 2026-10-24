"""Read-only validation for the Vinix7 source data and imported database."""

from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.vinix_etl import (
    DEFAULT_SOURCE, PRIMARY_KEYS, TABLE_COLUMNS, TABLE_ORDER,
    build_datasets, write_report,
)

def _check(checks: list[dict], name: str, ok: bool, details=None) -> None:
    checks.append({"name": name, "ok": bool(ok), "details": details})


def _scalar(conn, sql: str):
    return conn.execute(text(sql)).scalar_one()


def _validate_database(conn, expected: dict[str, int], checks: list[dict]) -> None:
    for table in TABLE_ORDER:
        actual = int(_scalar(conn, f'SELECT COUNT(*) FROM "{table}"'))
        _check(checks, f"count:{table}", actual == expected[table],
               {"expected": expected[table], "actual": actual})

    for table, primary_key in PRIMARY_KEYS.items():
        total = int(_scalar(conn, f'SELECT COUNT(*) FROM "{table}"'))
        unique = int(_scalar(conn, f'SELECT COUNT(DISTINCT "{primary_key}") FROM "{table}"'))
        _check(checks, f"primary_key:{table}", total == unique,
               {"rows": total, "distinct": unique})

    fk_queries = {
        "padukuhan.kalurahan_id": (
            "SELECT COUNT(*) FROM padukuhan c LEFT JOIN kalurahan p "
            "ON c.kalurahan_id = p.kalurahan_id WHERE p.kalurahan_id IS NULL"
        ),
        "data_pertanian.padukuhan_id": (
            "SELECT COUNT(*) FROM data_pertanian c LEFT JOIN padukuhan p "
            "ON c.padukuhan_id = p.padukuhan_id WHERE p.padukuhan_id IS NULL"
        ),
        "ketersediaan_bahan.bahan_id": (
            "SELECT COUNT(*) FROM ketersediaan_bahan c LEFT JOIN bahan_organik p "
            "ON c.bahan_id = p.bahan_id WHERE p.bahan_id IS NULL"
        ),
        "ketersediaan_bahan.padukuhan_id": (
            "SELECT COUNT(*) FROM ketersediaan_bahan c LEFT JOIN padukuhan p "
            "ON c.padukuhan_id = p.padukuhan_id WHERE p.padukuhan_id IS NULL"
        ),
        "produksi.produk_id": (
            "SELECT COUNT(*) FROM produksi c LEFT JOIN produk p "
            "ON c.produk_id = p.produk_id WHERE p.produk_id IS NULL"
        ),
        "penjualan.produk_id": (
            "SELECT COUNT(*) FROM penjualan c LEFT JOIN produk p "
            "ON c.produk_id = p.produk_id WHERE p.produk_id IS NULL"
        ),
    }
    for name, sql in fk_queries.items():
        orphans = int(_scalar(conn, sql))
        _check(checks, f"foreign_key:{name}", orphans == 0, {"orphans": orphans})

    min_bulan, max_bulan = conn.execute(text(
        "SELECT MIN(bulan), MAX(bulan) FROM penjualan"
    )).one()
    _check(checks, "sales:date_range",
           min_bulan == date(2020, 1, 1) and max_bulan == date(2025, 12, 1),
           {"min": str(min_bulan), "max": str(max_bulan),
            "expected_min": "2020-01-01", "expected_max": "2025-12-01"})

    sales_mismatch = int(_scalar(conn, """
        SELECT COUNT(*) FROM penjualan
        WHERE ABS(total_penjualan - (jumlah_terjual * harga_satuan)) > 0.01
    """))
    _check(checks, "sales:formula", sales_mismatch == 0, {"mismatches": sales_mismatch})

    production = conn.execute(text("""
        SELECT COALESCE(SUM(jumlah_produksi_varian), 0),
               COALESCE(SUM(jumlah_produksi_total), 0),
               COUNT(*) FILTER (WHERE jumlah_produksi_total < jumlah_produksi_varian)
        FROM produksi
    """)).one()
    _check(checks, "production:varian_rule",
           float(production[0]) == 142638.0 and float(production[1]) == 200392.0,
           {"sum_varian": float(production[0]), "sum_total": float(production[1]),
            "rows_total_lt_varian": int(production[2]),
            "note": "Jumlah_produksi_total tidak boleh dijumlahkan."})
    _check(checks, "production:total_ge_varian", int(production[2]) == 0,
           {"rows_total_lt_varian": int(production[2])})

    distance_non_null = int(_scalar(conn, """
        SELECT COUNT(*) FROM ketersediaan_bahan WHERE jarak_ke_produksi_km IS NOT NULL
    """))
    _check(checks, "organic_distance:all_null", distance_non_null == 0,
           {"non_null": distance_non_null})

    kalurahan_distance_null = int(_scalar(conn, """
        SELECT COUNT(*) FROM kalurahan WHERE jarak_kecamatan_km IS NULL
    """))
    _check(checks, "kalurahan:distance_datetime_null", kalurahan_distance_null == 1,
           {"null_rows": kalurahan_distance_null})

    synthetic = int(_scalar(conn, "SELECT COUNT(*) FROM data_pertanian"))
    real = int(_scalar(conn, "SELECT COUNT(*) FROM data_pertanian_real"))
    overlap = int(_scalar(conn, """
        SELECT COUNT(*) FROM data_pertanian a
        JOIN data_pertanian_real b ON a.agri_id = b.agri_id
    """))
    _check(checks, "synthetic_real:separate", synthetic == 511 and real == 14 and overlap == 0,
           {"synthetic": synthetic, "real": real, "id_overlap": overlap})

    real_columns = [column["name"] for column in conn.execute(text("""
        SELECT column_name AS name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'data_pertanian_real'
    """)).all()]
    _check(checks, "synthetic_real:no_padukuhan_join",
           "padukuhan_id" not in real_columns, {"columns": real_columns})


def main() -> int:
    parser = argparse.ArgumentParser(description="Validasi Vinix7 (read-only).")
    parser.add_argument("--database", action="store_true",
                        help="Periksa juga database PostgreSQL (hanya SELECT).")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE))
    parser.add_argument("--report", default=str(ROOT / "reports" / "validate.json"))
    args = parser.parse_args()

    result = build_datasets(args.source)
    checks: list[dict] = []
    _check(checks, "source:fatal_errors", not result.fatal_errors,
           {"fatal_errors": result.fatal_errors})
    _check(checks, "source:row_estimate",
           result.report["row_estimates"]["grand_total"] == 1588,
           result.report["row_estimates"])
    _check(checks, "source:organic_distance_null",
           result.report["organic_distance"]["stored_non_null"] == 0,
           result.report["organic_distance"])
    _check(checks, "source:production_varian_rule",
           result.report["production_rule"]["sum_varian"] == 142638.0,
           result.report["production_rule"])
    _check(checks, "source:sales_formula",
           result.report["sales_consistency"]["formula_mismatches"] == 0,
           result.report["sales_consistency"])
    report = {
        "mode": "validate",
        "database_checked": bool(args.database),
        "database_writes": False,
        "source": result.report["source"],
        "checks": checks,
        "failures": [item["name"] for item in checks if not item["ok"]],
    }

    if args.database:
        from scripts.db_utils import (
            assert_local_vinix7, assert_schema, database_url, load_environment,
            make_engine, sanitize_error,
        )

        load_environment()
        url = database_url()
        target = assert_local_vinix7(url)
        report["target"] = target
        engine = make_engine(url)
        try:
            schema = assert_schema(engine, TABLE_COLUMNS, ["staging_import_run"])
            report["schema"] = schema
            _check(checks, "schema:columns", not schema["missing_tables"], schema)
            with engine.connect() as conn:
                expected = {table: len(result.datasets[table]) for table in TABLE_ORDER}
                _validate_database(conn, expected, checks)
        except Exception as error:
            report["error"] = sanitize_error(error, url)
            _check(checks, "database:connection_or_schema", False, {"error": report["error"]})
        finally:
            engine.dispose()

    report["failures"] = [item["name"] for item in checks if not item["ok"]]
    write_report(report, args.report)
    print("VINIX7 VALIDATION")
    print(f"Database diperiksa: {report['database_checked']}")
    for item in checks:
        print(f"  {'OK  ' if item['ok'] else 'FAIL'} {item['name']}")
    print(f"Laporan: {args.report}")
    if report["failures"]:
        print("Gagal: " + ", ".join(report["failures"]), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
