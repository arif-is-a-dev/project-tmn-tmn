"""SQLAlchemy ORM models that mirror the existing db/schema.sql.

These models are read-only representations.  No table is created or
modified by these classes.
"""

from __future__ import annotations

from datetime import date as date_type
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Kalurahan(Base):
    __tablename__ = "kalurahan"

    kalurahan_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    kalurahan: Mapped[str] = mapped_column(String(100), nullable=False)
    luas_kalurahan_ha: Mapped[float | None] = mapped_column(Numeric(12, 4), nullable=True)
    jumlah_padukuhan: Mapped[int | None] = mapped_column(Integer, nullable=True)
    jumlah_rw: Mapped[int | None] = mapped_column(Integer, nullable=True)
    jumlah_rt: Mapped[int | None] = mapped_column(Integer, nullable=True)
    batas_utara: Mapped[str | None] = mapped_column(Text, nullable=True)
    batas_selatan: Mapped[str | None] = mapped_column(Text, nullable=True)
    batas_barat: Mapped[str | None] = mapped_column(Text, nullable=True)
    batas_timur: Mapped[str | None] = mapped_column(Text, nullable=True)
    jarak_kecamatan_km: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    jarak_kabupaten_km: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    jarak_provinsi_km: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    jarak_nasional_km: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)


class Padukuhan(Base):
    __tablename__ = "padukuhan"

    padukuhan_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    kalurahan_id: Mapped[str] = mapped_column(String(20), ForeignKey("kalurahan.kalurahan_id"), nullable=False)
    kalurahan: Mapped[str] = mapped_column(String(100), nullable=False)
    padukuhan: Mapped[str] = mapped_column(String(100), nullable=False)
    jumlah_rt: Mapped[int | None] = mapped_column(Integer, nullable=True)
    jumlah_rw: Mapped[int | None] = mapped_column(Integer, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)

    __table_args__ = (
        UniqueConstraint("kalurahan_id", "padukuhan", name="uq_padukuhan_kalurahan_padukuhan"),
    )


class DataPertanian(Base):
    __tablename__ = "data_pertanian"

    agri_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    kalurahan: Mapped[str] = mapped_column(String(100), nullable=False)
    padukuhan_id: Mapped[str] = mapped_column(String(20), ForeignKey("padukuhan.padukuhan_id"), nullable=False)
    padukuhan: Mapped[str] = mapped_column(String(100), nullable=False)
    komoditas: Mapped[str] = mapped_column(String(100), nullable=False)
    kelompok_komoditas: Mapped[str] = mapped_column(String(50), nullable=False)
    tahun: Mapped[int] = mapped_column(Integer, nullable=False)
    luas_panen_ha: Mapped[float] = mapped_column(Numeric(12, 4), nullable=False)
    luas_lahan_ha: Mapped[float] = mapped_column(Numeric(12, 4), nullable=False)
    jumlah_petani: Mapped[int] = mapped_column(Integer, nullable=False)
    jumlah_utp: Mapped[int] = mapped_column(Integer, nullable=False)
    jumlah_kelompok_tani: Mapped[int] = mapped_column(Integer, nullable=False)
    produksi: Mapped[float] = mapped_column(Numeric(18, 4), nullable=False)
    satuan_produksi_q: Mapped[str] = mapped_column(String(20), nullable=False)

    __table_args__ = (
        UniqueConstraint("padukuhan_id", "komoditas", "tahun", name="uq_pertanian_padukuhan_komoditas_tahun"),
    )


class BahanOrganik(Base):
    __tablename__ = "bahan_organik"

    bahan_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    jenis_bahan_organik: Mapped[str] = mapped_column(String(100), nullable=False)
    kategori_bahan: Mapped[str] = mapped_column(String(50), nullable=False)


class KetersediaanBahan(Base):
    __tablename__ = "ketersediaan_bahan"

    ketersediaan_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    bahan_id: Mapped[str] = mapped_column(String(20), ForeignKey("bahan_organik.bahan_id"), nullable=False)
    padukuhan_id: Mapped[str] = mapped_column(String(20), ForeignKey("padukuhan.padukuhan_id"), nullable=False)
    periode: Mapped[date_type] = mapped_column(Date, nullable=False)
    jumlah_ketersediaan: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    satuan: Mapped[str] = mapped_column(String(20), nullable=False)
    kontinuitas: Mapped[str] = mapped_column(String(50), nullable=False)
    jarak_ke_produksi_km: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    kemudahan_pengumpulan: Mapped[str] = mapped_column(String(50), nullable=False)
    status_pemanfaatan: Mapped[str] = mapped_column(String(50), nullable=False)
    frekuensi: Mapped[str] = mapped_column(String(50), nullable=False)
    musim: Mapped[str] = mapped_column(String(50), nullable=False)
    jumlah_sumber: Mapped[int] = mapped_column(Integer, nullable=False)
    status_data: Mapped[str] = mapped_column(String(30), nullable=False)

    __table_args__ = (
        UniqueConstraint("bahan_id", "padukuhan_id", "periode", name="uq_ketersediaan_bahan_padukuhan_periode"),
    )


class Produk(Base):
    __tablename__ = "produk"

    produk_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    nama_produk: Mapped[str] = mapped_column(String(200), nullable=False)
    jenis_produk: Mapped[str] = mapped_column(String(100), nullable=False)
    deskripsi: Mapped[str | None] = mapped_column(Text, nullable=True)
    manfaat: Mapped[str | None] = mapped_column(Text, nullable=True)
    harga: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    ukuran_kemasan: Mapped[str | None] = mapped_column(String(50), nullable=True)
    produsen: Mapped[str | None] = mapped_column(String(100), nullable=True)
    lokasi_produsen: Mapped[str | None] = mapped_column(String(200), nullable=True)
    kontak: Mapped[str | None] = mapped_column(String(100), nullable=True)
    stok_ketersediaan: Mapped[str | None] = mapped_column(String(50), nullable=True)
    foto_produk: Mapped[str | None] = mapped_column(String(500), nullable=True)


class Produksi(Base):
    __tablename__ = "produksi"

    produksi_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    produk_id: Mapped[str] = mapped_column(String(20), ForeignKey("produk.produk_id"), nullable=False)
    nama_produk: Mapped[str] = mapped_column(String(200), nullable=False)
    jenis_produk: Mapped[str] = mapped_column(String(100), nullable=False)
    jumlah_produksi_varian: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    jumlah_produksi_total: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    satuan: Mapped[str] = mapped_column(String(20), nullable=False)
    kapasitas_produk: Mapped[float | None] = mapped_column(Numeric(18, 2), nullable=True)
    bahan_baku_aktif: Mapped[str | None] = mapped_column(String(100), nullable=True)
    bahan_baku: Mapped[str | None] = mapped_column(String(200), nullable=True)
    jumlah_bahan_baku: Mapped[float | None] = mapped_column(Numeric(18, 3), nullable=True)
    periode_produksi: Mapped[int] = mapped_column(Integer, nullable=False)
    status_data: Mapped[str] = mapped_column(String(30), nullable=False)
    satuan_bahan_baku: Mapped[str | None] = mapped_column(String(20), nullable=True)
    satuan_stok: Mapped[str | None] = mapped_column(String(20), nullable=True)
    stok: Mapped[float | None] = mapped_column(Numeric(18, 3), nullable=True)

    __table_args__ = (
        UniqueConstraint("produk_id", "periode_produksi", name="uq_produksi_produk_periode"),
        CheckConstraint("jumlah_produksi_total >= jumlah_produksi_varian", name="ck_produksi_total_ge_varian"),
    )


class Penjualan(Base):
    __tablename__ = "penjualan"

    penjualan_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    produk_id: Mapped[str] = mapped_column(String(20), ForeignKey("produk.produk_id"), nullable=False)
    bulan: Mapped[date_type] = mapped_column(Date, nullable=False)
    produk: Mapped[str] = mapped_column(String(200), nullable=False)
    jumlah_terjual: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    harga_satuan: Mapped[float] = mapped_column(Numeric(14, 2), nullable=False)
    total_penjualan: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    satuan: Mapped[str | None] = mapped_column(String(20), nullable=True)
    kanal: Mapped[str | None] = mapped_column(String(50), nullable=True)
    status_data: Mapped[str | None] = mapped_column(String(30), nullable=True)

    __table_args__ = (
        UniqueConstraint("produk_id", "bulan", name="uq_penjualan_produk_bulan"),
        CheckConstraint("total_penjualan = jumlah_terjual * harga_satuan", name="ck_penjualan_formula"),
    )


class ProdukKatalogAudit(Base):
    __tablename__ = "produk_katalog_audit"

    produk_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    nama_produk: Mapped[str] = mapped_column(String(200), nullable=False)
    jenis_produk: Mapped[str] = mapped_column(String(100), nullable=False)
    deskripsi: Mapped[str | None] = mapped_column(Text, nullable=True)
    manfaat: Mapped[str | None] = mapped_column(Text, nullable=True)
    harga: Mapped[float | None] = mapped_column(Numeric(14, 2), nullable=True)
    ukuran_kemasan: Mapped[str | None] = mapped_column(String(50), nullable=True)
    produsen: Mapped[str | None] = mapped_column(String(100), nullable=True)
    lokasi_produsen: Mapped[str | None] = mapped_column(String(200), nullable=True)
    kontak: Mapped[str | None] = mapped_column(String(100), nullable=True)
    stok_ketersediaan: Mapped[str | None] = mapped_column(String(50), nullable=True)
    foto_produk: Mapped[str | None] = mapped_column(String(500), nullable=True)


class DataPertanianReal(Base):
    __tablename__ = "data_pertanian_real"

    agri_id: Mapped[str] = mapped_column(String(20), primary_key=True)
    wilayah: Mapped[str] = mapped_column(String(100), nullable=False)
    komoditas: Mapped[str] = mapped_column(String(100), nullable=False)
    luas_panen_ha: Mapped[float | None] = mapped_column(Numeric(12, 4), nullable=True)
    luas_lahan_ha: Mapped[float | None] = mapped_column(Numeric(12, 4), nullable=True)
    jumlah_utp: Mapped[int | None] = mapped_column(Integer, nullable=True)
    produksi: Mapped[float | None] = mapped_column(Numeric(18, 4), nullable=True)
    satuan_produksi: Mapped[str] = mapped_column(String(20), nullable=False)
    tahun_produksi: Mapped[int] = mapped_column(Integer, nullable=False)
    tahun_utp: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sumber_produksi: Mapped[str] = mapped_column(String(100), nullable=False)
    sumber_utp: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status_data: Mapped[str] = mapped_column(String(30), nullable=False)
    catatan: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        UniqueConstraint("wilayah", "komoditas", "tahun_produksi", name="uq_real_wilayah_komoditas_tahun"),
    )


class StagingImportRun(Base):
    __tablename__ = "staging_import_run"

    run_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    started_at: Mapped[Any] = mapped_column(DateTime(timezone=True), nullable=False)
    finished_at: Mapped[Any | None] = mapped_column(DateTime(timezone=True), nullable=True)
    source_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    mode: Mapped[str] = mapped_column(String(10), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    report: Mapped[Any] = mapped_column(Text, nullable=False)