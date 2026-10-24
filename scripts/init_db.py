"""Create the Vinix7 schema. Default mode is dry-run; --apply never resets."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.vinix_etl import TABLE_COLUMNS, write_report


SCHEMA_PATH = ROOT / "db" / "schema.sql"
SCHEMA_TABLES = list(TABLE_COLUMNS) + ["staging_import_run"]
CONFIRMATION = "INISIALISASI VINIX7"


def _load_schema() -> str:
    sql = SCHEMA_PATH.read_text(encoding="utf-8")
    upper = sql.upper()
    for forbidden in ("IF NOT EXISTS", "DROP TABLE", "TRUNCATE", "DELETE FROM"):
        if forbidden in upper:
            raise RuntimeError(f"schema.sql mengandung perintah terlarang: {forbidden}")
    return sql


def main() -> int:
    parser = argparse.ArgumentParser(description="Inisialisasi skema Vinix7.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Hanya periksa (default).")
    mode.add_argument("--apply", action="store_true", help="Buat tabel setelah konfirmasi.")
    parser.add_argument("--report", default=None)
    args = parser.parse_args()
    apply = bool(args.apply)
    report_path = Path(args.report) if args.report else ROOT / "reports" / (
        "init_apply.json" if apply else "init_dry_run.json"
    )
    sql = _load_schema()
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "mode": "apply" if apply else "dry-run",
        "database_writes": False,
        "schema_path": str(SCHEMA_PATH),
        "tables": SCHEMA_TABLES,
        "statement_count": sql.count(";"),
    }

    if not apply:
        from scripts.db_utils import load_environment, target_info, ENV_VAR
        load_environment()
        url = os.getenv(ENV_VAR, "").strip()
        report["target"] = target_info(url) if url else {"configured": False}
        write_report(report, report_path)
        print("VINIX7 INIT DRY-RUN")
        print(f"Schema : {SCHEMA_PATH}")
        print(f"Tabel  : {', '.join(SCHEMA_TABLES)}")
        print(f"Target : {report['target']}")
        print("Tidak ada koneksi atau perubahan database. Jalankan --apply setelah persetujuan.")
        return 0

    from sqlalchemy import inspect
    from scripts.db_utils import (
        ENV_VAR, assert_local_vinix7, database_url, load_environment,
        make_engine, sanitize_error,
    )

    load_environment()
    url = database_url()
    target = assert_local_vinix7(url)
    report["target"] = target
    engine = make_engine(url)
    try:
        existing = set(inspect(engine).get_table_names(schema="public"))
        present = sorted(existing & set(SCHEMA_TABLES))
        if present:
            raise RuntimeError(
                "Tabel target sudah ada; init menolak reset. Tabel ditemukan: "
                + ", ".join(present)
            )
        print(f"Target database: {target['host']}:{target['port']}/{target['database']}")
        print("Tabel yang akan dibuat: " + ", ".join(SCHEMA_TABLES))
        print("Mode ini tidak menghapus atau mengganti tabel yang sudah ada.")
        answer = input(f"Ketik '{CONFIRMATION}' untuk melanjutkan: ").strip()
        if answer != CONFIRMATION:
            print("Dibatalkan. Database tidak diubah.")
            return 2
        with engine.begin() as conn:
            conn.exec_driver_sql(sql)
        created = set(inspect(engine).get_table_names(schema="public")) & set(SCHEMA_TABLES)
        missing = sorted(set(SCHEMA_TABLES) - created)
        if missing:
            raise RuntimeError(f"Tabel gagal dibuat: {missing}")
        report["database_writes"] = True
        report["created_tables"] = sorted(created)
        write_report(report, report_path)
        print("Skema berhasil dibuat. Database belum diisi data.")
        return 0
    except Exception as error:
        report["error"] = sanitize_error(error, url)
        write_report(report, report_path)
        print(f"GAGAL: {report['error']}", file=sys.stderr)
        return 1
    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
