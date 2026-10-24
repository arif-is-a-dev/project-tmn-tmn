"""Vinix7 Excel importer. Default is dry-run; --apply requires confirmation."""

from __future__ import annotations

import argparse
import json
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.vinix_etl import (
    DEFAULT_SOURCE, PRIMARY_KEYS, TABLE_COLUMNS, TABLE_ORDER,
    build_datasets, print_summary, write_report,
)

CONFIRMATION = "IMPOR VINIX7"


def main() -> int:
    parser = argparse.ArgumentParser(description="Impor Excel Vinix7 ke PostgreSQL.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Validasi tanpa database (default).")
    mode.add_argument("--apply", action="store_true", help="Impor setelah konfirmasi eksplisit.")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE))
    parser.add_argument("--report", default=None)
    args = parser.parse_args()
    apply = bool(args.apply)
    report_path = Path(args.report) if args.report else ROOT / "reports" / (
        "apply.json" if apply else "dry_run.json"
    )

    result = build_datasets(args.source)
    result.report["mode"] = "apply" if apply else "dry-run"
    result.report["database_writes"] = False
    print_summary(result)

    if result.fatal_errors:
        write_report(result.report, report_path)
        print("\nImpor dihentikan: ada fatal error. Tidak ada penulisan database.", file=sys.stderr)
        return 1

    if not apply:
        write_report(result.report, report_path)
        print(f"\nLaporan dry-run: {report_path}")
        print("Tidak ada koneksi atau penulisan database.")
        return 0

    from sqlalchemy import inspect
    from scripts.db_utils import (
        assert_local_vinix7, assert_schema, database_url, load_environment,
        make_engine, sanitize_error, upsert_frame,
    )

    load_environment()
    url = database_url()
    target = assert_local_vinix7(url)
    engine = make_engine(url)
    run_id = uuid.uuid4().hex
    started_at = datetime.now(timezone.utc)
    result.report["run_id"] = run_id
    result.report["started_at"] = started_at.isoformat()
    result.report["target"] = target
    committed = False

    try:
        schema = assert_schema(engine, TABLE_COLUMNS, ["staging_import_run"])
        result.report["schema"] = schema
        print(f"\nTarget database: {target['host']}:{target['port']}/{target['database']}")
        print("Tabel dan kolom wajib sudah diperiksa (read-only).")
        answer = input(f"Ketik '{CONFIRMATION}' untuk melanjutkan impor: ").strip()
        if answer != CONFIRMATION:
            print("Dibatalkan. Database tidak diubah.")
            write_report(result.report, report_path)
            return 2

        imported: dict[str, int] = {}
        with engine.begin() as conn:
            for table in TABLE_ORDER:
                imported[table] = upsert_frame(
                    conn, table, result.datasets[table], PRIMARY_KEYS[table]
                )
            counts = {
                table: int(conn.execute(text(f'SELECT COUNT(*) FROM "{table}"')).scalar_one())
                for table in TABLE_ORDER
            }
            finished_at = datetime.now(timezone.utc)
            result.report["database_writes"] = True
            result.report["status"] = "applied"
            result.report["imported_rows"] = imported
            result.report["database_row_counts"] = counts
            result.report["finished_at"] = finished_at.isoformat()
            conn.execute(text("""
                INSERT INTO staging_import_run
                    (run_id, started_at, finished_at, source_sha256, mode, status, report)
                VALUES
                    (:run_id, :started_at, :finished_at, :source_sha256, 'apply', 'applied',
                     CAST(:report AS JSONB))
            """), {
                "run_id": run_id,
                "started_at": started_at,
                "finished_at": finished_at,
                "source_sha256": result.report["source"]["sha256"],
                "report": json.dumps(result.report, ensure_ascii=False, default=str),
            })
        committed = True
        write_report(result.report, report_path)
        print("\nImpor selesai dalam satu transaksi.")
        print(f"Baris diimpor: {sum(imported.values())}")
        print(f"Laporan apply: {report_path}")
        return 0
    except Exception as error:
        result.report["status"] = "failed"
        if not committed:
            result.report["database_writes"] = False
        result.report["error"] = sanitize_error(error, url)
        try:
            write_report(result.report, report_path)
        except Exception as report_error:
            print(f"Laporan gagal ditulis: {report_error}", file=sys.stderr)
        if committed:
            print(f"\nGAGAL setelah commit; database sudah berubah: {result.report['error']}", file=sys.stderr)
        else:
            print(f"\nGAGAL (transaksi di-rollback): {result.report['error']}", file=sys.stderr)
        return 1
    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
