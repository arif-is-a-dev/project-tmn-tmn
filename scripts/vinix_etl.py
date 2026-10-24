"""Pure data layer for the Vinix7 Excel import.

This module never imports SQLAlchemy/psycopg2 and never writes to PostgreSQL.
It reads the workbook explicitly, standardizes the seven ETL sheets, validates
them, and returns a JSON-serializable report.
"""

from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "Data Projek Vinix (1).xlsx"

ALL_SHEETS = [
    "Data_produksi_pupuk",
    "Data_Bahan_Organik",
    "Produk_Katalog",
    "Data_Produk_Katalog",
    "Data_Penjualan",
    "Data Wilayah_Kalurahan",
    "Data_Wilayah_Padukuhan",
    "Data_Pertanian",
    "Copy of Data_Penjualan",
    "Copy of Data Pertanian_Dummy",
    "Data Pertanian_real",
    "Copy of Data Wilayah_Kalurahan",
    "Copy of Data Wilayah_Padukuhan",
]

ETL_SHEETS = [
    "Data_produksi_pupuk",
    "Data_Bahan_Organik",
    "Data_Produk_Katalog",
    "Data_Penjualan",
    "Data Wilayah_Kalurahan",
    "Data_Wilayah_Padukuhan",
    "Data_Pertanian",
    "Produk_Katalog",
    "Data Pertanian_real",
]

ARCHIVE_SHEETS = [
    "Copy of Data_Penjualan",
    "Copy of Data Pertanian_Dummy",
    "Copy of Data Wilayah_Kalurahan",
    "Copy of Data Wilayah_Padukuhan",
]

SHEET_TO_TABLE = {
    "Data_produksi_pupuk": "produksi",
    "Data_Bahan_Organik": "bahan_organik + ketersediaan_bahan",
    "Data_Produk_Katalog": "produk",
    "Produk_Katalog": "produk_katalog_audit",
    "Data_Penjualan": "penjualan",
    "Data Wilayah_Kalurahan": "kalurahan",
    "Data_Wilayah_Padukuhan": "padukuhan",
    "Data_Pertanian": "data_pertanian",
    "Data Pertanian_real": "data_pertanian_real",
}

TABLE_COLUMNS = {
    "kalurahan": [
        "kalurahan_id", "kalurahan", "luas_kalurahan_ha", "jumlah_padukuhan",
        "jumlah_rw", "jumlah_rt", "batas_utara", "batas_selatan",
        "batas_barat", "batas_timur", "jarak_kecamatan_km",
        "jarak_kabupaten_km", "jarak_provinsi_km", "jarak_nasional_km",
        "latitude", "longitude",
    ],
    "padukuhan": [
        "padukuhan_id", "kalurahan_id", "kalurahan", "padukuhan",
        "jumlah_rt", "jumlah_rw", "latitude", "longitude",
    ],
    "data_pertanian": [
        "agri_id", "kalurahan", "padukuhan_id", "padukuhan", "komoditas",
        "kelompok_komoditas", "tahun", "luas_panen_ha", "luas_lahan_ha",
        "jumlah_petani", "jumlah_utp", "jumlah_kelompok_tani", "produksi",
        "satuan_produksi_q",
    ],
    "bahan_organik": ["bahan_id", "jenis_bahan_organik", "kategori_bahan"],
    "ketersediaan_bahan": [
        "ketersediaan_id", "bahan_id", "padukuhan_id", "periode",
        "jumlah_ketersediaan", "satuan", "kontinuitas",
        "jarak_ke_produksi_km", "kemudahan_pengumpulan",
        "status_pemanfaatan", "frekuensi", "musim", "jumlah_sumber",
        "status_data",
    ],
    "produk": [
        "produk_id", "nama_produk", "jenis_produk", "deskripsi", "manfaat",
        "harga", "ukuran_kemasan", "produsen", "lokasi_produsen", "kontak",
        "stok_ketersediaan", "foto_produk",
    ],
    "produksi": [
        "produksi_id", "produk_id", "nama_produk", "jenis_produk",
        "jumlah_produksi_varian", "jumlah_produksi_total", "satuan",
        "kapasitas_produk", "bahan_baku_aktif", "bahan_baku",
        "jumlah_bahan_baku", "periode_produksi", "status_data",
        "satuan_bahan_baku", "satuan_stok", "stok",
    ],
    "penjualan": [
        "penjualan_id", "produk_id", "bulan", "produk", "jumlah_terjual",
        "harga_satuan", "total_penjualan", "satuan", "kanal", "status_data",
    ],
    "produk_katalog_audit": [
        "produk_id", "nama_produk", "jenis_produk", "deskripsi", "manfaat",
        "harga", "ukuran_kemasan", "produsen", "lokasi_produsen", "kontak",
        "stok_ketersediaan", "foto_produk",
    ],
    "data_pertanian_real": [
        "agri_id", "wilayah", "komoditas", "luas_panen_ha", "luas_lahan_ha",
        "jumlah_utp", "produksi", "satuan_produksi", "tahun_produksi",
        "tahun_utp", "sumber_produksi", "sumber_utp", "status_data", "catatan",
    ],
}

PRIMARY_KEYS = {
    "kalurahan": "kalurahan_id",
    "padukuhan": "padukuhan_id",
    "data_pertanian": "agri_id",
    "bahan_organik": "bahan_id",
    "ketersediaan_bahan": "ketersediaan_id",
    "produk": "produk_id",
    "produksi": "produksi_id",
    "penjualan": "penjualan_id",
    "produk_katalog_audit": "produk_id",
    "data_pertanian_real": "agri_id",
}

NATURAL_KEYS = {
    "padukuhan": ["kalurahan_id", "padukuhan"],
    "data_pertanian": ["padukuhan_id", "komoditas", "tahun"],
    "ketersediaan_bahan": ["bahan_id", "padukuhan_id", "periode"],
    "produksi": ["produk_id", "periode_produksi"],
    "penjualan": ["produk_id", "bulan"],
    "data_pertanian_real": ["wilayah", "komoditas", "tahun_produksi"],
}

REQUIRED_COLUMNS = {
    "kalurahan": ["kalurahan_id", "kalurahan"],
    "padukuhan": ["padukuhan_id", "kalurahan_id", "kalurahan", "padukuhan"],
    "data_pertanian": [
        "agri_id", "kalurahan", "padukuhan_id", "padukuhan", "komoditas",
        "kelompok_komoditas", "tahun", "luas_panen_ha", "luas_lahan_ha",
        "jumlah_petani", "jumlah_utp", "jumlah_kelompok_tani", "produksi",
        "satuan_produksi_q",
    ],
    "bahan_organik": ["bahan_id", "jenis_bahan_organik", "kategori_bahan"],
    "ketersediaan_bahan": [
        "ketersediaan_id", "bahan_id", "padukuhan_id", "periode",
        "jumlah_ketersediaan", "satuan", "kontinuitas",
        "kemudahan_pengumpulan", "status_pemanfaatan", "frekuensi", "musim",
        "jumlah_sumber", "status_data",
    ],
    "produk": ["produk_id", "nama_produk", "jenis_produk"],
    "produksi": [
        "produksi_id", "produk_id", "nama_produk", "jenis_produk",
        "jumlah_produksi_varian", "jumlah_produksi_total", "satuan",
        "periode_produksi", "status_data",
    ],
    "penjualan": [
        "penjualan_id", "produk_id", "bulan", "produk", "jumlah_terjual",
        "harga_satuan", "total_penjualan",
    ],
    "produk_katalog_audit": ["produk_id", "nama_produk", "jenis_produk"],
    "data_pertanian_real": [
        "agri_id", "wilayah", "komoditas", "satuan_produksi",
        "tahun_produksi", "sumber_produksi", "status_data",
    ],
}

TABLE_ORDER = [
    "kalurahan", "padukuhan", "data_pertanian", "bahan_organik",
    "ketersediaan_bahan", "produk", "produksi", "penjualan",
    "produk_katalog_audit", "data_pertanian_real",
]


@dataclass
class EtlResult:
    datasets: dict[str, pd.DataFrame]
    report: dict[str, Any]

    @property
    def fatal_errors(self) -> list[dict[str, Any]]:
        return self.report["fatal_errors"]


PII_COLUMNS = {"kontak"}


def _is_blank(value: Any) -> bool:
    if value is None:
        return True
    try:
        result = pd.isna(value)
    except (TypeError, ValueError):
        return False
    return bool(result) if not isinstance(result, (list, tuple, np.ndarray)) else False


def _text(value: Any) -> str | None:
    if _is_blank(value):
        return None
    text = str(value).strip()
    return text or None


def _num(value: Any) -> float | None:
    if _is_blank(value) or isinstance(value, bool):
        return None
    if isinstance(value, (int, float, np.integer, np.floating)):
        return float(value)
    text = str(value).strip().replace(" ", "").replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return None


def _int(value: Any) -> int | None:
    number = _num(value)
    if number is None or not number.is_integer():
        return None
    return int(number)


def _date(value: Any) -> date | None:
    if _is_blank(value):
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    parsed = pd.to_datetime(value, errors="coerce")
    if pd.isna(parsed):
        return None
    return parsed.date()


def _parse_quantity(value: Any) -> tuple[float | None, str | None]:
    """Parse values such as '4.103 kg' where dots are thousands separators."""
    if _is_blank(value):
        return None, None
    if isinstance(value, (int, float, np.integer, np.floating)):
        return float(value), None
    text = str(value).strip()
    match = re.match(r"^([0-9][0-9.,]*)\s*([A-Za-z]+)?$", text)
    if not match:
        return None, None
    number_text = match.group(1)
    unit = match.group(2).strip() if match.group(2) else None
    if "," in number_text and "." in number_text:
        number_text = number_text.replace(".", "").replace(",", ".")
    elif number_text.count(".") > 1:
        number_text = number_text.replace(".", "")
    elif "." in number_text:
        left, right = number_text.split(".", 1)
        if left and len(right) == 3:
            number_text = left + right
    try:
        return float(number_text), unit
    except ValueError:
        return None, unit


def _distance(value: Any) -> tuple[float | None, str]:
    if _is_blank(value):
        return None, "blank"
    if isinstance(value, (datetime, date, np.datetime64, pd.Timestamp)):
        return None, "datetime"
    if isinstance(value, str) and re.search(r"\d{4}[-/]\d{1,2}[-/]\d{1,2}", value.strip()):
        return None, "datetime"
    number = _num(value)
    return number, "numeric" if number is not None else "invalid"


def _same_value(left: Any, right: Any) -> bool:
    if _is_blank(left) and _is_blank(right):
        return True
    if _is_blank(left) or _is_blank(right):
        return False
    try:
        return abs(float(left) - float(right)) < 1e-9
    except (TypeError, ValueError):
        return str(left).strip() == str(right).strip()


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _fatal(errors: list[dict[str, Any]], code: str, message: str, **context: Any) -> None:
    errors.append({"code": code, "message": message, **context})


def _warn(warnings: list[dict[str, Any]], code: str, message: str, count: int = 1, **context: Any) -> None:
    warnings.append({"code": code, "message": message, "count": count, **context})


def _require(row: pd.Series, fields: list[str], sheet: str, row_number: int,
             errors: list[dict[str, Any]]) -> bool:
    missing = [field for field in fields if _is_blank(row.get(field))]
    if missing:
        _fatal(errors, "missing_required_value", "Nilai wajib kosong.", sheet=sheet,
               excel_row=row_number, fields=missing)
        return False
    return True


def _table_summary(name: str, sheet: str, source_rows: int, frame: pd.DataFrame,
                   rejected: list[int], primary_key: str,
                   natural_key: list[str] | None = None,
                   collapsed_duplicates: int = 0) -> dict[str, Any]:
    pk_duplicates = int(frame[primary_key].duplicated().sum()) if primary_key in frame else 0
    natural_duplicates = (
        int(frame.duplicated(subset=natural_key).sum()) if natural_key else 0
    )
    return {
        "source_sheet": sheet,
        "source_rows": source_rows,
        "valid_rows": int(len(frame)),
        "rejected_rows": len(rejected),
        "rejected_excel_rows": rejected[:50],
        "primary_key": primary_key,
        "primary_key_unique": pk_duplicates == 0,
        "primary_key_duplicates": pk_duplicates,
        "natural_key": natural_key,
        "natural_key_duplicates": natural_duplicates,
        "collapsed_duplicates": collapsed_duplicates,
        "columns": list(frame.columns),
    }


def _fk_orphans(child: pd.DataFrame, child_column: str,
                parent: pd.DataFrame, parent_column: str) -> int:
    return int((~child[child_column].isin(set(parent[parent_column]))).sum())


def _sheet_audit(raw: dict[str, pd.DataFrame]) -> list[dict[str, Any]]:
    result = []
    for sheet in ALL_SHEETS:
        frame = raw[sheet]
        result.append({
            "sheet": sheet,
            "role": "archive_only" if sheet in ARCHIVE_SHEETS else "etl_source",
            "rows": int(len(frame)),
            "columns": int(len(frame.columns)),
            "column_info": [
                {
                    "name": str(column),
                    "pandas_dtype": str(frame[column].dtype),
                    "non_null": int(frame[column].notna().sum()),
                    "unique_non_null": int(frame[column].nunique(dropna=True)),
                }
                for column in frame.columns
            ],
        })
    return result


def _compare_copy(main: pd.DataFrame, copy: pd.DataFrame, key: str,
                  columns: list[str]) -> list[dict[str, str]]:
    left = main.drop_duplicates(subset=[key]).set_index(key)
    right = copy.dropna(subset=[key]).drop_duplicates(subset=[key]).set_index(key)
    differences = []
    for row_key in left.index:
        if row_key not in right.index:
            continue
        for column in columns:
            if column not in right.columns:
                continue
            if not _same_value(left.at[row_key, column], right.at[row_key, column]):
                differences.append({"key": str(row_key), "column": column})
    return differences


def _archive_audit(raw: dict[str, pd.DataFrame]) -> list[dict[str, Any]]:
    return [
        {
            "sheet": "Copy of Data_Penjualan",
            "role": "archive_only",
            "source_rows": int(len(raw["Copy of Data_Penjualan"])),
            "material_differences": _compare_copy(
                raw["Data_Penjualan"], raw["Copy of Data_Penjualan"],
                "Penjualan_id", list(raw["Data_Penjualan"].columns),
            ),
            "note": "Kolom tambahan setelah 10 kolom sumber adalah blok pivot, bukan data ETL.",
        },
        {
            "sheet": "Copy of Data Pertanian_Dummy",
            "role": "archive_only",
            "source_rows": int(len(raw["Copy of Data Pertanian_Dummy"])),
            "material_differences": _compare_copy(
                raw["Data_Pertanian"], raw["Copy of Data Pertanian_Dummy"],
                "agri_id", list(raw["Data_Pertanian"].columns),
            ),
            "note": "Baris setelah 511 data adalah catatan/sumber, bukan data ETL.",
        },
        {
            "sheet": "Copy of Data Wilayah_Kalurahan",
            "role": "archive_only",
            "source_rows": int(len(raw["Copy of Data Wilayah_Kalurahan"])),
            "material_differences": _compare_copy(
                raw["Data Wilayah_Kalurahan"], raw["Copy of Data Wilayah_Kalurahan"],
                "kalurahan_id", list(raw["Data Wilayah_Kalurahan"].columns),
            ),
            "note": "Baris tambahan adalah catatan; nilai numerik dibandingkan secara numerik.",
        },
        {
            "sheet": "Copy of Data Wilayah_Padukuhan",
            "role": "archive_only",
            "source_rows": int(len(raw["Copy of Data Wilayah_Padukuhan"])),
            "material_differences": _compare_copy(
                raw["Data_Wilayah_Padukuhan"], raw["Copy of Data Wilayah_Padukuhan"],
                "padukuhan_id", list(raw["Data_Wilayah_Padukuhan"].columns),
            ),
            "note": "Baris tambahan adalah catatan; nilai numerik dibandingkan secara numerik.",
        },
    ]


def _transform_kalurahan(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                         warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data Wilayah_Kalurahan"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, ["kalurahan_id", "kalurahan"], sheet, row_number, errors):
            rejected.append(row_number)
            continue
        distance, distance_kind = _distance(row.get("jarak_kecamatan_km"))
        if distance_kind == "datetime":
            _warn(warnings, "kalurahan_distance_datetime_null",
                  "jarak_kecamatan_km berupa tanggal pada satu kalurahan; disimpan NULL.",
                  excel_row=row_number, kalurahan_id=_text(row.get("kalurahan_id")))
        elif distance_kind == "invalid":
            _warn(warnings, "kalurahan_distance_invalid",
                  "jarak_kecamatan_km tidak dapat dibaca; disimpan NULL.",
                  excel_row=row_number, kalurahan_id=_text(row.get("kalurahan_id")))
        records.append({
            "kalurahan_id": _text(row.get("kalurahan_id")),
            "kalurahan": _text(row.get("kalurahan")),
            "luas_kalurahan_ha": _num(row.get("luas_kalurahan_ha")),
            "jumlah_padukuhan": _int(row.get("jumlah_padukuhan")),
            "jumlah_rw": _int(row.get("jumlah_rw")),
            "jumlah_rt": _int(row.get("jumlah_rt")),
            "batas_utara": _text(row.get("batas_utara")),
            "batas_selatan": _text(row.get("batas_selatan")),
            "batas_barat": _text(row.get("batas_barat")),
            "batas_timur": _text(row.get("batas_timur")),
            "jarak_kecamatan_km": distance,
            "jarak_kabupaten_km": _num(row.get("jarak_kabupaten_km")),
            "jarak_provinsi_km": _num(row.get("jarak_provinsi_km")),
            "jarak_nasional_km": _num(row.get("jarak_nasional_km")),
            "latitude": _num(row.get("latitude")),
            "longitude": _num(row.get("longitude")),
        })
    return pd.DataFrame(records, columns=TABLE_COLUMNS["kalurahan"]), rejected


def _transform_padukuhan(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                         warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data_Wilayah_Padukuhan"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    required = ["padukuhan_id", "kalurahan_id", "kalurahan", "padukuhan"]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        records.append({
            "padukuhan_id": _text(row.get("padukuhan_id")),
            "kalurahan_id": _text(row.get("kalurahan_id")),
            "kalurahan": _text(row.get("kalurahan")),
            "padukuhan": _text(row.get("padukuhan")),
            "jumlah_rt": _int(row.get("jumlah_rt")),
            "jumlah_rw": _int(row.get("jumlah_rw")),
            "latitude": _num(row.get("latitude")),
            "longitude": _num(row.get("longitude")),
        })
    return pd.DataFrame(records, columns=TABLE_COLUMNS["padukuhan"]), rejected


def _transform_pertanian(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                         warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data_Pertanian"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    required = [
        "agri_id", "kalurahan", "padukuhan_id", "padukuhan", "komoditas",
        "kelompok_komoditas", "tahun", "luas_panen_ha", "luas_lahan_ha",
        "jumlah_petani", "jumlah_utp", "jumlah_kelompok_tani", "produksi",
        "satuan_produksi_q",
    ]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        record = {
            "agri_id": _text(row.get("agri_id")),
            "kalurahan": _text(row.get("kalurahan")),
            "padukuhan_id": _text(row.get("padukuhan_id")),
            "padukuhan": _text(row.get("padukuhan")),
            "komoditas": _text(row.get("komoditas")),
            "kelompok_komoditas": _text(row.get("kelompok_komoditas")),
            "tahun": _int(row.get("tahun")),
            "luas_panen_ha": _num(row.get("luas_panen_ha")),
            "luas_lahan_ha": _num(row.get("luas_lahan_ha")),
            "jumlah_petani": _int(row.get("jumlah_petani")),
            "jumlah_utp": _int(row.get("jumlah_utp")),
            "jumlah_kelompok_tani": _int(row.get("jumlah_kelompok_tani")),
            "produksi": _num(row.get("produksi")),
            "satuan_produksi_q": _text(row.get("satuan_produksi_q")),
        }
        numeric_required = [
            "tahun", "luas_panen_ha", "luas_lahan_ha", "jumlah_petani",
            "jumlah_utp", "jumlah_kelompok_tani", "produksi",
        ]
        if any(record[field] is None for field in numeric_required):
            _fatal(errors, "invalid_required_numeric", "Nilai numerik wajib tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, agri_id=record["agri_id"])
            rejected.append(row_number)
            continue
        records.append(record)
    return pd.DataFrame(records, columns=TABLE_COLUMNS["data_pertanian"]), rejected


def _transform_bahan_organik(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                             warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, pd.DataFrame, list[int]]:
    sheet = "Data_Bahan_Organik"
    frame = raw[sheet]
    bahan: dict[str, dict[str, Any]] = {}
    ketersediaan: list[dict[str, Any]] = []
    rejected: list[int] = []
    distance_kinds: Counter[str] = Counter()
    required = [
        "bahan_id", "jenis_bahan_organik", "kategori_bahan", "ketersediaan_id",
        "padukuhan_id", "periode", "jumlah_ketersediaan", "satuan",
        "kontinuitas", "kemudahan_pengumpulan", "status_pemanfaatan",
        "frekuensi", "musim", "jumlah_sumber", "status_data",
    ]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        bahan_id = _text(row.get("bahan_id"))
        bahan_record = {
            "bahan_id": bahan_id,
            "jenis_bahan_organik": _text(row.get("jenis_bahan_organik")),
            "kategori_bahan": _text(row.get("kategori_bahan")),
        }
        if bahan_id in bahan and bahan[bahan_id] != bahan_record:
            _fatal(errors, "conflicting_bahan_attributes",
                   "bahan_id yang sama memiliki atribut berbeda.",
                   sheet=sheet, excel_row=row_number, bahan_id=bahan_id)
            rejected.append(row_number)
            continue
        bahan[bahan_id] = bahan_record
        periode = _date(row.get("periode"))
        jumlah = _num(row.get("jumlah_ketersediaan"))
        jumlah_sumber = _int(row.get("jumlah_sumber"))
        if periode is None or jumlah is None or jumlah_sumber is None:
            _fatal(errors, "invalid_organic_numeric_or_date",
                   "periode/jumlah_ketersediaan/jumlah_sumber tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, ketersediaan_id=_text(row.get("ketersediaan_id")))
            rejected.append(row_number)
            continue
        _, distance_kind = _distance(row.get("jarak_ke_produksi_km"))
        distance_kinds[distance_kind] += 1
        ketersediaan.append({
            "ketersediaan_id": _text(row.get("ketersediaan_id")),
            "bahan_id": bahan_id,
            "padukuhan_id": _text(row.get("padukuhan_id")),
            "periode": periode,
            "jumlah_ketersediaan": jumlah,
            "satuan": _text(row.get("satuan")),
            "kontinuitas": _text(row.get("kontinuitas")),
            "jarak_ke_produksi_km": None,
            "kemudahan_pengumpulan": _text(row.get("kemudahan_pengumpulan")),
            "status_pemanfaatan": _text(row.get("status_pemanfaatan")),
            "frekuensi": _text(row.get("frekuensi")),
            "musim": _text(row.get("musim")),
            "jumlah_sumber": jumlah_sumber,
            "status_data": _text(row.get("status_data")),
        })
    _warn(warnings, "organic_distance_unverified",
          "Semua jarak_ke_produksi_km disimpan NULL karena sumber belum terverifikasi.",
          count=int(len(frame)),
          datetime_values=distance_kinds.get("datetime", 0),
          numeric_values=distance_kinds.get("numeric", 0))
    bahan_frame = pd.DataFrame(list(bahan.values()), columns=TABLE_COLUMNS["bahan_organik"])
    ketersediaan_frame = pd.DataFrame(ketersediaan, columns=TABLE_COLUMNS["ketersediaan_bahan"])
    return bahan_frame, ketersediaan_frame, rejected


def _transform_produk(raw: dict[str, pd.DataFrame], sheet: str,
                      errors: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, ["produk_id", "Nama_Produk", "Jenis_Produk"], sheet, row_number, errors):
            rejected.append(row_number)
            continue
        records.append({
            "produk_id": _text(row.get("produk_id")),
            "nama_produk": _text(row.get("Nama_Produk")),
            "jenis_produk": _text(row.get("Jenis_Produk")),
            "deskripsi": _text(row.get("Deskripsi")),
            "manfaat": _text(row.get("Manfaat")),
            "harga": _num(row.get("Harga")),
            "ukuran_kemasan": _text(row.get("Ukuran_Kemasan")),
            "produsen": _text(row.get("Produsen")),
            "lokasi_produsen": _text(row.get("Lokasi_Produsen")),
            "kontak": _text(row.get("Kontak")),
            "stok_ketersediaan": _text(row.get("Stok_Ketersediaan")),
            "foto_produk": _text(row.get("Foto Produk")),
        })
    return pd.DataFrame(records, columns=TABLE_COLUMNS["produk"]), rejected


def _transform_produksi(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                        warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data_produksi_pupuk"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    status_typos = 0
    required = [
        "produksi_id", "produk_id", "Nama_Produk", "Jenis_Produk",
        "Jumlah_produksi_varian", "Jumlah_produksi_total", "Satuan",
        "Periode_produksi", "status_data",
    ]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        bahan_value, bahan_unit = _parse_quantity(row.get("jumlah_bahan_baku"))
        stok_value, stok_unit = _parse_quantity(row.get("Stok"))
        varian = _num(row.get("Jumlah_produksi_varian"))
        total = _num(row.get("Jumlah_produksi_total"))
        periode = _int(row.get("Periode_produksi"))
        if varian is None or total is None or periode is None:
            _fatal(errors, "invalid_production_numeric",
                   "Jumlah produksi atau periode tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, produksi_id=_text(row.get("produksi_id")))
            rejected.append(row_number)
            continue
        if bahan_value is None or stok_value is None:
            _fatal(errors, "invalid_production_quantity",
                   "jumlah_bahan_baku atau Stok tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, produksi_id=_text(row.get("produksi_id")))
            rejected.append(row_number)
            continue
        if total < varian:
            _fatal(errors, "production_total_lt_varian",
                   "Jumlah_produksi_total lebih kecil dari Jumlah_produksi_varian.",
                   sheet=sheet, excel_row=row_number, produksi_id=_text(row.get("produksi_id")))
        status = _text(row.get("status_data"))
        if status == "Sintestis":
            status_typos += 1
        records.append({
            "produksi_id": _text(row.get("produksi_id")),
            "produk_id": _text(row.get("produk_id")),
            "nama_produk": _text(row.get("Nama_Produk")),
            "jenis_produk": _text(row.get("Jenis_Produk")),
            "jumlah_produksi_varian": varian,
            "jumlah_produksi_total": total,
            "satuan": _text(row.get("Satuan")),
            "kapasitas_produk": _num(row.get("Kapasitas-produk")),
            "bahan_baku_aktif": _text(row.get("Bahan_baku_aktif")),
            "bahan_baku": _text(row.get("Bahan_baku")),
            "jumlah_bahan_baku": bahan_value,
            "periode_produksi": periode,
            "status_data": status,
            "satuan_bahan_baku": bahan_unit,
            "satuan_stok": stok_unit,
            "stok": stok_value,
        })
    frame_out = pd.DataFrame(records, columns=TABLE_COLUMNS["produksi"])
    if status_typos:
        _warn(warnings, "production_status_typo",
              "Nilai status_data 'Sintestis' dipertahankan apa adanya.",
              count=status_typos)
    if not frame_out.empty:
        different = int((frame_out["jumlah_produksi_total"] != frame_out["jumlah_produksi_varian"]).sum())
        _warn(warnings, "production_total_is_repeated_group_total",
              "Jumlah_produksi_total adalah total kelompok berulang; jangan dijumlahkan.",
              count=different,
              sum_varian=float(frame_out["jumlah_produksi_varian"].sum()),
              sum_total=float(frame_out["jumlah_produksi_total"].sum()))
    return frame_out, rejected


def _transform_penjualan(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                         warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data_Penjualan"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    zero_quantity = 0
    required = [
        "Penjualan_id", "Produk_id", "Bulan", "Produk", "Jumlah_Terjual",
        "Harga_Satuan", "Total_Penjualan",
    ]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        bulan = _date(row.get("Bulan"))
        quantity = _num(row.get("Jumlah_Terjual"))
        price = _num(row.get("Harga_Satuan"))
        total = _num(row.get("Total_Penjualan"))
        if bulan is None or quantity is None or price is None or total is None:
            _fatal(errors, "invalid_sales_numeric_or_date",
                   "Bulan atau nilai penjualan tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, penjualan_id=_text(row.get("Penjualan_id")))
            rejected.append(row_number)
            continue
        if bulan.day != 1:
            _fatal(errors, "sales_month_not_first_day",
                   "Bulan penjualan bukan tanggal awal bulan.",
                   sheet=sheet, excel_row=row_number, penjualan_id=_text(row.get("Penjualan_id")))
        if abs(total - quantity * price) > 0.01:
            _fatal(errors, "sales_total_mismatch",
                   "Total_Penjualan tidak sama dengan Jumlah_Terjual x Harga_Satuan.",
                   sheet=sheet, excel_row=row_number, penjualan_id=_text(row.get("Penjualan_id")))
        if quantity == 0:
            zero_quantity += 1
        records.append({
            "penjualan_id": _text(row.get("Penjualan_id")),
            "produk_id": _text(row.get("Produk_id")),
            "bulan": bulan,
            "produk": _text(row.get("Produk")),
            "jumlah_terjual": quantity,
            "harga_satuan": price,
            "total_penjualan": total,
            "satuan": _text(row.get("Satuan")),
            "kanal": _text(row.get("Kanal")),
            "status_data": _text(row.get("Status_Data")),
        })
    if zero_quantity:
        _warn(warnings, "sales_zero_quantity_kept",
              "Baris penjualan dengan jumlah 0 dipertahankan.", count=zero_quantity)
    return pd.DataFrame(records, columns=TABLE_COLUMNS["penjualan"]), rejected


def _transform_pertanian_real(raw: dict[str, pd.DataFrame], errors: list[dict[str, Any]],
                              warnings: list[dict[str, Any]]) -> tuple[pd.DataFrame, list[int]]:
    sheet = "Data Pertanian_real"
    frame = raw[sheet]
    records: list[dict[str, Any]] = []
    rejected: list[int] = []
    required = ["agri_id", "wilayah", "komoditas", "satuan_produksi",
                "tahun_produksi", "sumber_produksi", "status_data"]
    for index, row in frame.iterrows():
        row_number = int(index) + 2
        if not _require(row, required, sheet, row_number, errors):
            rejected.append(row_number)
            continue
        tahun = _int(row.get("tahun_produksi"))
        if tahun is None:
            _fatal(errors, "invalid_real_year", "tahun_produksi tidak dapat dibaca.",
                   sheet=sheet, excel_row=row_number, agri_id=_text(row.get("agri_id")))
            rejected.append(row_number)
            continue
        records.append({
            "agri_id": _text(row.get("agri_id")),
            "wilayah": _text(row.get("wilayah")),
            "komoditas": _text(row.get("komoditas")),
            "luas_panen_ha": _num(row.get("luas_panen_ha")),
            "luas_lahan_ha": _num(row.get("luas_lahan_ha")),
            "jumlah_utp": _int(row.get("jumlah_utp")),
            "produksi": _num(row.get("produksi")),
            "satuan_produksi": _text(row.get("satuan_produksi")),
            "tahun_produksi": tahun,
            "tahun_utp": _int(row.get("tahun_utp")),
            "sumber_produksi": _text(row.get("sumber_produksi")),
            "sumber_utp": _text(row.get("sumber_utp")),
            "status_data": _text(row.get("status_data")),
            "catatan": _text(row.get("catatan")),
        })
    frame_out = pd.DataFrame(records, columns=TABLE_COLUMNS["data_pertanian_real"])
    if not frame_out.empty:
        for column in ["luas_lahan_ha", "jumlah_utp", "produksi"]:
            missing = int(frame_out[column].isna().sum())
            if missing:
                _warn(warnings, f"real_agriculture_missing_{column}",
                      f"Data real pertanian memiliki nilai kosong pada {column}.",
                      count=missing)
    return frame_out, rejected


def _summarize_warnings(warnings: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for warning in warnings:
        code = warning["code"]
        item = grouped.setdefault(code, {
            "code": code,
            "message": warning["message"],
            "count": 0,
            "examples": [],
        })
        item["count"] += int(warning.get("count", 1))
        if "excel_row" in warning and len(item["examples"]) < 10:
            item["examples"].append({
                key: value for key, value in warning.items()
                if key not in {"code", "message", "count"}
            })
        for key in ("datetime_values", "numeric_values", "sum_varian", "sum_total"):
            if key in warning:
                item[key] = warning[key]
    return list(grouped.values())


def _mapping_confirmations() -> list[dict[str, str]]:
    return [
        {"item": "Data_Produk_Katalog", "table": "produk", "status": "confirmed",
         "note": "Katalog utama untuk ETL."},
        {"item": "Produk_Katalog", "table": "produk_katalog_audit", "status": "confirmed",
         "note": "Katalog kedua hanya untuk audit; tidak digabung ke produk."},
        {"item": "Data_Pertanian", "table": "data_pertanian", "status": "confirmed",
         "note": "Data sintetis tingkat padukuhan; tidak dicampur dengan data riil."},
        {"item": "Data Pertanian_real", "table": "data_pertanian_real", "status": "confirmed",
         "note": "Data riil tingkat kecamatan; tidak dapat di-join ke padukuhan."},
        {"item": "Copy of ...", "table": "arsip", "status": "confirmed",
         "note": "Semua sheet Copy of hanya diarsipkan dan bukan sumber ETL."},
        {"item": "jarak_ke_produksi_km", "table": "ketersediaan_bahan", "status": "blocked",
         "note": "Nilai sumber belum terverifikasi; semua nilai disimpan NULL. AHP-SAW belum dapat dijalankan."},
        {"item": "status_data 'Sintestis'", "table": "produksi", "status": "needs_confirmation",
         "note": "Nilai dipertahankan apa adanya; perlu keputusan normalisasi ke 'Sintetis'."},
        {"item": "data_pertanian_real", "table": "data_pertanian_real", "status": "needs_confirmation",
         "note": "Perlu konfirmasi apakah tabel ini ditampilkan di aplikasi atau hanya arsip audit."},
        {"item": "hasil_scoring", "table": "hasil_scoring", "status": "confirmed",
         "note": "Ranking produk berdasarkan prediksi penjualan, bukan ranking potensi bahan organik."},
        {"item": "hasil_prediksi", "table": "hasil_prediksi", "status": "confirmed",
         "note": "Prediksi penjualan 2026; bukan ranking bahan organik."},
    ]


def build_datasets(source: str | Path = DEFAULT_SOURCE) -> EtlResult:
    path = Path(source).resolve()
    if not path.exists():
        raise FileNotFoundError(f"Sumber tidak ditemukan: {path}")

    raw = pd.read_excel(path, sheet_name=ALL_SHEETS, engine="openpyxl")
    missing_sheets = [sheet for sheet in ALL_SHEETS if sheet not in raw]
    if missing_sheets:
        raise ValueError(f"Sheet wajib tidak ditemukan: {missing_sheets}")

    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    kalurahan, kalurahan_rejected = _transform_kalurahan(raw, errors, warnings)
    padukuhan, padukuhan_rejected = _transform_padukuhan(raw, errors, warnings)
    pertanian, pertanian_rejected = _transform_pertanian(raw, errors, warnings)
    bahan, ketersediaan, bahan_rejected = _transform_bahan_organik(raw, errors, warnings)
    produk, produk_rejected = _transform_produk(raw, "Data_Produk_Katalog", errors)
    katalog_audit, katalog_audit_rejected = _transform_produk(raw, "Produk_Katalog", errors)
    produksi, produksi_rejected = _transform_produksi(raw, errors, warnings)
    penjualan, penjualan_rejected = _transform_penjualan(raw, errors, warnings)
    pertanian_real, pertanian_real_rejected = _transform_pertanian_real(raw, errors, warnings)

    datasets = {
        "kalurahan": kalurahan,
        "padukuhan": padukuhan,
        "data_pertanian": pertanian,
        "bahan_organik": bahan,
        "ketersediaan_bahan": ketersediaan,
        "produk": produk,
        "produksi": produksi,
        "penjualan": penjualan,
        "produk_katalog_audit": katalog_audit,
        "data_pertanian_real": pertanian_real,
    }

    tables = {
        "kalurahan": _table_summary(
            "kalurahan", "Data Wilayah_Kalurahan", len(raw["Data Wilayah_Kalurahan"]),
            kalurahan, kalurahan_rejected, PRIMARY_KEYS["kalurahan"],
        ),
        "padukuhan": _table_summary(
            "padukuhan", "Data_Wilayah_Padukuhan", len(raw["Data_Wilayah_Padukuhan"]),
            padukuhan, padukuhan_rejected, PRIMARY_KEYS["padukuhan"],
            NATURAL_KEYS["padukuhan"],
        ),
        "data_pertanian": _table_summary(
            "data_pertanian", "Data_Pertanian", len(raw["Data_Pertanian"]),
            pertanian, pertanian_rejected, PRIMARY_KEYS["data_pertanian"],
            NATURAL_KEYS["data_pertanian"],
        ),
        "bahan_organik": _table_summary(
            "bahan_organik", "Data_Bahan_Organik", len(raw["Data_Bahan_Organik"]),
            bahan, bahan_rejected, PRIMARY_KEYS["bahan_organik"],
            collapsed_duplicates=max(0, len(raw["Data_Bahan_Organik"]) - len(bahan) - len(bahan_rejected)),
        ),
        "ketersediaan_bahan": _table_summary(
            "ketersediaan_bahan", "Data_Bahan_Organik", len(raw["Data_Bahan_Organik"]),
            ketersediaan, bahan_rejected, PRIMARY_KEYS["ketersediaan_bahan"],
            NATURAL_KEYS["ketersediaan_bahan"],
        ),
        "produk": _table_summary(
            "produk", "Data_Produk_Katalog", len(raw["Data_Produk_Katalog"]),
            produk, produk_rejected, PRIMARY_KEYS["produk"],
        ),
        "produksi": _table_summary(
            "produksi", "Data_produksi_pupuk", len(raw["Data_produksi_pupuk"]),
            produksi, produksi_rejected, PRIMARY_KEYS["produksi"],
            NATURAL_KEYS["produksi"],
        ),
        "penjualan": _table_summary(
            "penjualan", "Data_Penjualan", len(raw["Data_Penjualan"]),
            penjualan, penjualan_rejected, PRIMARY_KEYS["penjualan"],
            NATURAL_KEYS["penjualan"],
        ),
        "produk_katalog_audit": _table_summary(
            "produk_katalog_audit", "Produk_Katalog", len(raw["Produk_Katalog"]),
            katalog_audit, katalog_audit_rejected, PRIMARY_KEYS["produk_katalog_audit"],
        ),
        "data_pertanian_real": _table_summary(
            "data_pertanian_real", "Data Pertanian_real", len(raw["Data Pertanian_real"]),
            pertanian_real, pertanian_real_rejected, PRIMARY_KEYS["data_pertanian_real"],
            NATURAL_KEYS["data_pertanian_real"],
        ),
    }

    for table_name, summary in tables.items():
        if not summary["primary_key_unique"]:
            examples = datasets[table_name][
                datasets[table_name][summary["primary_key"]].duplicated(keep=False)
            ][summary["primary_key"]].drop_duplicates().head(10).tolist()
            _fatal(errors, "duplicate_primary_key", "Primary key duplikat.",
                   table=table_name, examples=examples)
        if summary["natural_key_duplicates"]:
            _fatal(errors, "duplicate_natural_key", "Natural key duplikat.",
                   table=table_name, natural_key=summary["natural_key"])

    fk_checks = [
        ("padukuhan", "kalurahan_id", "kalurahan", "kalurahan_id"),
        ("data_pertanian", "padukuhan_id", "padukuhan", "padukuhan_id"),
        ("ketersediaan_bahan", "bahan_id", "bahan_organik", "bahan_id"),
        ("ketersediaan_bahan", "padukuhan_id", "padukuhan", "padukuhan_id"),
        ("produksi", "produk_id", "produk", "produk_id"),
        ("penjualan", "produk_id", "produk", "produk_id"),
    ]
    foreign_keys = []
    for child, child_column, parent, parent_column in fk_checks:
        orphans = _fk_orphans(datasets[child], child_column, datasets[parent], parent_column)
        foreign_keys.append({
            "child": child,
            "column": child_column,
            "parent": parent,
            "parent_column": parent_column,
            "orphans": orphans,
        })
        if orphans:
            _fatal(errors, "foreign_key_orphan", "Foreign key tidak memiliki pasangan.",
                   child=child, column=child_column, parent=parent, orphans=orphans)

    synthetic_ids = set(datasets["data_pertanian"]["agri_id"])
    real_ids = set(datasets["data_pertanian_real"]["agri_id"])
    overlap = sorted(synthetic_ids & real_ids)
    if overlap:
        _fatal(errors, "synthetic_real_id_overlap",
               "ID data pertanian sintetis dan riil bertumpang tindih.", examples=overlap[:10])

    if not datasets["ketersediaan_bahan"].empty:
        non_null_distance = int(datasets["ketersediaan_bahan"]["jarak_ke_produksi_km"].notna().sum())
        if non_null_distance:
            _fatal(errors, "organic_distance_not_null",
                   "jarak_ke_produksi_km harus NULL sampai sumber terverifikasi.",
                   non_null_rows=non_null_distance)

    sales_mismatches = 0
    if not penjualan.empty:
        sales_mismatches = int((
            (penjualan["total_penjualan"] - penjualan["jumlah_terjual"] * penjualan["harga_satuan"]).abs() > 0.01
        ).sum())
        if sales_mismatches:
            _fatal(errors, "sales_formula_mismatch", "Rumus penjualan tidak konsisten.",
                   rows=sales_mismatches)

    production_sum_varian = float(produksi["jumlah_produksi_varian"].sum()) if not produksi.empty else 0.0
    production_sum_total = float(produksi["jumlah_produksi_total"].sum()) if not produksi.empty else 0.0
    production_rows_differ = int((
        produksi["jumlah_produksi_total"] != produksi["jumlah_produksi_varian"]
    ).sum()) if not produksi.empty else 0

    catalogs_identical = bool(
        produk.shape == katalog_audit.shape
        and all(_same_value(a, b) for a, b in zip(produk.to_numpy().ravel(), katalog_audit.to_numpy().ravel()))
    )

    total_core = sum(len(datasets[name]) for name in [
        "kalurahan", "padukuhan", "data_pertanian", "bahan_organik",
        "ketersediaan_bahan", "produk", "produksi", "penjualan",
    ])
    total_audit = len(datasets["produk_katalog_audit"])
    total_real = len(datasets["data_pertanian_real"])

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "mode": "dry-run",
        "database_writes": False,
        "source": {
            "path": str(path),
            "sha256": _sha256(path),
            "sheet_count": len(ALL_SHEETS),
            "etl_sheet_count": len(ETL_SHEETS),
            "archive_sheet_count": len(ARCHIVE_SHEETS),
            "row_column_note": "Baris/kolom adalah extent pandas tanpa header; baris berformat kosong tidak dihitung.",
        },
        "sheet_audit": _sheet_audit(raw),
        "mapping": SHEET_TO_TABLE,
        "notebook_references": {
            "sheets_read": [
                "Data_produksi_pupuk", "Data_Bahan_Organik", "Data_Produk_Katalog",
                "Data_Penjualan", "Data Wilayah_Kalurahan",
                "Data_Wilayah_Padukuhan", "Data_Pertanian",
            ],
            "core_tables": [
                "kalurahan", "padukuhan", "data_pertanian", "bahan_organik",
                "ketersediaan_bahan", "produk", "produksi", "penjualan",
            ],
            "result_tables": [
                "hasil_peringkat_potensi_organik", "perbandingan_ranking_organik",
                "hasil_scoring", "hasil_prediksi",
            ],
            "note": "hasil_scoring adalah ranking produk berdasarkan prediksi penjualan, bukan ranking bahan organik.",
        },
        "tables": tables,
        "foreign_keys": foreign_keys,
        "row_estimates": {
            "core_total": total_core,
            "catalog_audit": total_audit,
            "real_agriculture": total_real,
            "grand_total": total_core + total_audit + total_real,
        },
        "production_rule": {
            "aggregation_column": "jumlah_produksi_varian",
            "sum_varian": production_sum_varian,
            "sum_total": production_sum_total,
            "rows_total_differs": production_rows_differ,
            "note": "Jumlah_produksi_total adalah total kelompok berulang; jangan dijumlahkan.",
        },
        "sales_consistency": {
            "rows": int(len(penjualan)),
            "formula_mismatches": sales_mismatches,
            "zero_quantity_rows": int((penjualan["jumlah_terjual"] == 0).sum()) if not penjualan.empty else 0,
            "min_bulan": str(penjualan["bulan"].min()) if not penjualan.empty else None,
            "max_bulan": str(penjualan["bulan"].max()) if not penjualan.empty else None,
        },
        "organic_distance": {
            "source_values": int(len(raw["Data_Bahan_Organik"])),
            "stored_non_null": int(ketersediaan["jarak_ke_produksi_km"].notna().sum()) if not ketersediaan.empty else 0,
            "stored_null": int(ketersediaan["jarak_ke_produksi_km"].isna().sum()) if not ketersediaan.empty else 0,
            "status": "blocked_pending_verified_source",
        },
        "catalogs": {
            "main_rows": int(len(produk)),
            "audit_rows": int(len(katalog_audit)),
            "identical": catalogs_identical,
            "stored_separately": True,
        },
        "synthetic_real": {
            "synthetic_rows": int(len(pertanian)),
            "real_rows": int(len(pertanian_real)),
            "id_overlap": overlap,
            "separate_tables": True,
        },
        "real_agriculture_missing": {
            "luas_lahan_ha": int(pertanian_real["luas_lahan_ha"].isna().sum()) if not pertanian_real.empty else 0,
            "jumlah_utp": int(pertanian_real["jumlah_utp"].isna().sum()) if not pertanian_real.empty else 0,
            "produksi": int(pertanian_real["produksi"].isna().sum()) if not pertanian_real.empty else 0,
        },
        "archive_audit": _archive_audit(raw),
        "mapping_confirmations": _mapping_confirmations(),
        "pii": {
            "redacted_in_reports": sorted(PII_COLUMNS),
            "note": "Nilai kontak tidak ditulis ke laporan/log; kolom tetap dimuat ke tabel produk.",
        },
        "warnings": _summarize_warnings(warnings),
        "fatal_errors": errors,
    }
    return EtlResult(datasets=datasets, report=report)


def write_report(report: dict[str, Any], path: str | Path) -> Path:
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, default=str),
        encoding="utf-8",
    )
    return destination


def print_summary(result: EtlResult) -> None:
    report = result.report
    print("VINIX7 DRY-RUN")
    print(f"Sumber : {report['source']['path']}")
    print(f"SHA256 : {report['source']['sha256']}")
    print(f"Sheet  : {report['source']['sheet_count']} (ETL {report['source']['etl_sheet_count']}, arsip {report['source']['archive_sheet_count']})")
    print("\nTabel:")
    for name, summary in report["tables"].items():
        print(
            f"  {name:24} sumber={summary['source_rows']:4} "
            f"valid={summary['valid_rows']:4} ditolak={summary['rejected_rows']:2} "
            f"PK unik={summary['primary_key_unique']} "
            f"natural dup={summary['natural_key_duplicates']}"
        )
    estimates = report["row_estimates"]
    print(f"\nPerkiraan impor: core={estimates['core_total']} + audit={estimates['catalog_audit']} + real={estimates['real_agriculture']} = {estimates['grand_total']}")
    print(f"Produksi: sum varian={report['production_rule']['sum_varian']:.0f}, sum total={report['production_rule']['sum_total']:.0f} (total tidak boleh dijumlahkan)")
    print(f"Penjualan: {report['sales_consistency']['min_bulan']} s/d {report['sales_consistency']['max_bulan']}, mismatch={report['sales_consistency']['formula_mismatches']}")
    print(f"Jarak bahan organik non-NULL: {report['organic_distance']['stored_non_null']}")
    print(f"Warning: {len(report['warnings'])} kelompok; fatal: {len(report['fatal_errors'])}")
    for warning in report["warnings"]:
        print(f"  WARN {warning['code']}: {warning['message']} ({warning['count']})")
    for error in report["fatal_errors"][:20]:
        print(f"  FATAL {error['code']}: {error['message']}")
