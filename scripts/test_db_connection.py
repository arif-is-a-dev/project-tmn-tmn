"""Test koneksi read-only ke PostgreSQL vinix7 tanpa mengubah database."""

from __future__ import annotations

import sys

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[1] / "scripts"))

from db_utils import assert_local_vinix7, database_url, load_environment, make_engine, sanitize_error
from sqlalchemy import text


def main() -> int:
    load_environment()
    url = database_url()
    info = assert_local_vinix7(url)
    print(f"Target: host={info['host']} port={info['port']} database={info['database']} user={info['user']}")
    try:
        engine = make_engine(url)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1")).scalar()
            version = conn.execute(text("SELECT version()")).scalar()
        engine.dispose()
    except Exception as error:
        print("GAGAL - koneksi tidak berhasil:")
        print(sanitize_error(error, url))
        return 1

    if result != 1:
        print("GAGAL - hasil SELECT 1 tidak sesuai.")
        return 1

    print("BERHASIL - koneksi read-only OK.")
    print(f"Versi PostgreSQL: {version}")
    print("Tidak ada perubahan database.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
