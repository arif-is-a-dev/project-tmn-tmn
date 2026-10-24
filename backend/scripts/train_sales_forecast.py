#!/usr/bin/env python3
"""Train ExtraTreesRegressor sales forecast model from PostgreSQL data.

Reproduces the pipeline from Projek_vinix.ipynb cells 328-412.
Reads from PostgreSQL penjualan table, engineers lag features, trains
an ExtraTreesRegressor with tuned hyperparameters, evaluates on temporal
splits, and saves the final model as a joblib pipeline.

Usage:
    cd project-ebil
    .venv_backend/Scripts/python.exe -I backend/scripts/train_sales_forecast.py

Output:
    backend/models/sales_forecast_pipeline.pkl   — fitted Pipeline
    backend/models/sales_forecast_metadata.json  — training metadata
"""

from __future__ import annotations

import json
import os
import sys
from datetime import date, datetime
from pathlib import Path

# Ensure project root is on path for imports
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
os.chdir(str(PROJECT_ROOT))

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import ExtraTreesRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
import joblib

from backend.app.config import DatabaseSettings
from backend.app.database import get_db_session
from sqlalchemy import text


# ── Configuration (matches notebook cells 401, 405) ──────────────────────────

MODEL_PARAMS = dict(
    n_estimators=500,
    max_depth=15,
    min_samples_leaf=2,
    max_features=0.8,
    random_state=42,
    n_jobs=-1,
)

FEATURES = ["Produk", "bulan_kalender", "lag_1", "lag_2", "lag_3", "lag_12"]
TARGET = "Jumlah_Terjual"

OUTPUT_DIR = PROJECT_ROOT / "backend" / "models"
MODEL_PATH = OUTPUT_DIR / "sales_forecast_pipeline.pkl"
META_PATH = OUTPUT_DIR / "sales_forecast_metadata.json"


# ── Metrics ───────────────────────────────────────────────────────────────────

def compute_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    """Compute MAE, RMSE, WAPE matching notebook definitions."""
    mae = mean_absolute_error(y_true, y_pred)
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    # WAPE: sum(|actual - predicted|) / sum(|actual|) * 100
    wape = np.sum(np.abs(y_true - y_pred)) / np.sum(np.abs(y_true)) * 100 if np.sum(np.abs(y_true)) > 0 else float("inf")
    return {"mae": round(mae, 4), "rmse": round(rmse, 4), "wape": round(wape, 4)}


# ── Data loading ──────────────────────────────────────────────────────────────

def load_data() -> pd.DataFrame:
    """Load penjualan from PostgreSQL and prepare for ML pipeline."""
    settings = DatabaseSettings()
    with get_db_session(settings) as session:
        rows = session.execute(text(
            "SELECT produk, bulan, jumlah_terjual FROM penjualan ORDER BY produk, bulan"
        )).all()

    df = pd.DataFrame(rows, columns=["Produk", "Bulan", TARGET])
    df["Bulan"] = pd.to_datetime(df["Bulan"])
    df[TARGET] = df[TARGET].astype(float)

    print(f"[DATA] Loaded {len(df)} records")
    print(f"[DATA] Date range: {df['Bulan'].min().date()} to {df['Bulan'].max().date()}")
    print(f"[DATA] Products: {df['Produk'].nunique()}")
    print(f"[DATA] Zero-value records: {(df[TARGET] == 0).sum()}")

    return df


# ── Feature engineering (notebook cell 349) ───────────────────────────────────

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """Create bulan_kalender and lag features per product."""
    df = df.sort_values(["Produk", "Bulan"]).reset_index(drop=True)
    df["bulan_kalender"] = df["Bulan"].dt.month

    for lag in [1, 2, 3, 12]:
        df[f"lag_{lag}"] = df.groupby("Produk")[TARGET].shift(lag)

    # Count NaN from lag creation (first 12 months per product have no lag_12)
    nan_count = df[FEATURES].isnull().sum().sum()
    print(f"[FEATURES] Engineered {len(FEATURES)} features, {nan_count} NaN values from lag creation")

    return df


# ── Preprocessing pipeline (notebook cell 361) ────────────────────────────────

def build_preprocessor():
    """Build ColumnTransformer matching notebook cell 361."""
    return ColumnTransformer(
        transformers=[
            ("produk", OneHotEncoder(handle_unknown="ignore"), ["Produk"]),
            ("numerik", "passthrough", ["bulan_kalender", "lag_1", "lag_2", "lag_3", "lag_12"]),
        ]
    )


# ── Main training pipeline ───────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("VINIX7 Sales Forecast Model Training")
    print("=" * 60)

    # 1. Load data
    df = load_data()

    # 2. Engineer features
    df = engineer_features(df)

    # 3. Drop rows with NaN features (first 12 months per product)
    df_model = df.dropna(subset=FEATURES).reset_index(drop=True)
    print(f"[SPLIT] After dropping NaN lags: {len(df_model)} rows")

    # 4. Temporal splits (notebook cell 363)
    train_mask = df_model["Bulan"] < "2024-01-01"
    val_mask = (df_model["Bulan"] >= "2024-01-01") & (df_model["Bulan"] < "2025-01-01")
    test_mask = df_model["Bulan"] >= "2025-01-01"

    train_df = df_model[train_mask]
    val_df = df_model[val_mask]
    test_df = df_model[test_mask]

    print(f"[SPLIT] Train: {len(train_df)} rows (< 2024)")
    print(f"[SPLIT] Validation: {len(val_df)} rows (2024)")
    print(f"[SPLIT] Test: {len(test_df)} rows (>= 2025)")

    # Validate split sizes match notebook expectations
    assert len(train_df) == 396, f"Expected 396 train rows, got {len(train_df)}"
    assert len(val_df) == 132, f"Expected 132 validation rows, got {len(val_df)}"
    assert len(test_df) == 132, f"Expected 132 test rows, got {len(test_df)}"

    X_train = train_df[FEATURES]
    y_train = train_df[TARGET]
    X_val = val_df[FEATURES]
    y_val = val_df[TARGET]
    X_test = test_df[FEATURES]
    y_test = test_df[TARGET]

    # 5. Evaluate on validation set (2024)
    print("\n[EVAL] Training model for validation on 2024 data...")
    val_pipeline = Pipeline([
        ("preprocessor", build_preprocessor()),
        ("model", ExtraTreesRegressor(**MODEL_PARAMS)),
    ])
    val_pipeline.fit(X_train, y_train)
    val_pred = val_pipeline.predict(X_val)
    val_pred = np.maximum(val_pred, 0)  # Clamp negatives to 0
    val_metrics = compute_metrics(y_val.values, val_pred)
    print(f"[EVAL] Validation (2024): MAE={val_metrics['mae']}, RMSE={val_metrics['rmse']}, WAPE={val_metrics['wape']}%")

    # 6. Evaluate on test set (2025) using train+val trained model
    print("\n[EVAL] Evaluating on 2025 test data...")
    train_val_df = pd.concat([train_df, val_df]).reset_index(drop=True)
    test_pipeline = Pipeline([
        ("preprocessor", build_preprocessor()),
        ("model", ExtraTreesRegressor(**MODEL_PARAMS)),
    ])
    test_pipeline.fit(train_val_df[FEATURES], train_val_df[TARGET])
    test_pred = test_pipeline.predict(X_test)
    test_pred = np.maximum(test_pred, 0)
    test_metrics = compute_metrics(y_test.values, test_pred)
    print(f"[EVAL] Test (2025): MAE={test_metrics['mae']}, RMSE={test_metrics['rmse']}, WAPE={test_metrics['wape']}%")

    # 7. Train final model on ALL historical data (notebook cell 405)
    print("\n[TRAIN] Training final model on all historical data...")
    final_pipeline = Pipeline([
        ("preprocessor", build_preprocessor()),
        ("model", ExtraTreesRegressor(**MODEL_PARAMS)),
    ])
    final_pipeline.fit(df_model[FEATURES], df_model[TARGET])
    print(f"[TRAIN] Final model trained on {len(df_model)} rows")

    # 8. Recursive 12-month prediction for 2026 (notebook cell 407)
    print("\n[PREDICT] Generating 12-month recursive forecast for 2026...")
    products = sorted(df_model["Produk"].unique())
    predictions_2026 = []

    for produk in products:
        # Get last 12 months of actual data for lag initialization
        prod_history = df_model[df_model["Produk"] == produk].sort_values("Bulan")
        recent = prod_history[TARGET].tail(12).tolist()

        for month in range(1, 13):
            bulan_kal = month
            lag_1 = recent[-1] if len(recent) >= 1 else 0
            lag_2 = recent[-2] if len(recent) >= 2 else 0
            lag_3 = recent[-3] if len(recent) >= 3 else 0
            lag_12 = recent[-12] if len(recent) >= 12 else 0

            input_row = pd.DataFrame([{
                "Produk": produk,
                "bulan_kalender": bulan_kal,
                "lag_1": lag_1,
                "lag_2": lag_2,
                "lag_3": lag_3,
                "lag_12": lag_12,
            }])

            pred = final_pipeline.predict(input_row)[0]
            pred = max(pred, 0.0)  # Clamp negative to 0
            pred = round(pred, 2)

            predictions_2026.append({
                "Bulan": f"2026-{month:02d}-01",
                "Produk": produk,
                "Prediksi_Penjualan": pred,
            })

            # Update recent history for next iteration (recursive)
            recent.append(pred)
            if len(recent) > 12:
                recent.pop(0)

    df_prediksi = pd.DataFrame(predictions_2026)
    print(f"[PREDICT] Generated {len(df_prediksi)} predictions ({len(products)} products x 12 months)")
    print(f"[PREDICT] Total predicted volume 2026: {df_prediksi['Prediksi_Penjualan'].sum():.2f}")

    # Per-product summary
    print("\n[PREDICT] Per-product 2026 forecast summary:")
    summary = df_prediksi.groupby("Produk")["Prediksi_Penjualan"].agg(["sum", "mean"])
    summary.columns = ["Total_2026", "Rata_rata_Bulanan"]
    for _, row in summary.iterrows():
        print(f"  {_}: Total={row['Total_2026']:.2f}, Rata-rata={row['Rata_rata_Bulanan']:.2f}")

    # 9. Save artifacts
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Save model pipeline
    joblib.dump(final_pipeline, MODEL_PATH)
    print(f"\n[SAVE] Model saved to: {MODEL_PATH}")
    print(f"[SAVE] Model size: {MODEL_PATH.stat().st_size / 1024:.1f} KB")

    # Save metadata
    import sklearn
    metadata = {
        "model_type": "ExtraTreesRegressor",
        "model_params": MODEL_PARAMS,
        "features": FEATURES,
        "target": TARGET,
        "preprocessing": "ColumnTransformer(OneHotEncoder(Produk) + passthrough(numerics))",
        "training_date": datetime.now().isoformat(),
        "data_range": {
            "start": str(df["Bulan"].min().date()),
            "end": str(df["Bulan"].max().date()),
            "total_records": len(df),
            "records_after_lag_drop": len(df_model),
        },
        "splits": {
            "train_rows": len(train_df),
            "validation_rows": len(val_df),
            "test_rows": len(test_df),
        },
        "metrics": {
            "validation_2024": val_metrics,
            "test_2025": test_metrics,
        },
        "predictions_2026": {
            "total_predictions": len(df_prediksi),
            "products": len(products),
            "total_predicted_volume": round(df_prediksi["Prediksi_Penjualan"].sum(), 2),
        },
        "sklearn_version": sklearn.__version__,
        "python_version": sys.version.split()[0],
        "notes": [
            "Model trained on PostgreSQL penjualan table (not original Excel).",
            "253 zero-value transactions included (not filtered).",
            "Recursive forecasting: each month prediction feeds into next month lags.",
            "Negative predictions clamped to 0.",
            "handle_unknown='ignore' in OneHotEncoder for unseen products.",
        ],
    }

    with open(META_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)
    print(f"[SAVE] Metadata saved to: {META_PATH}")

    print("\n" + "=" * 60)
    print("Training complete. Review metrics before deploying.")
    print("=" * 60)


if __name__ == "__main__":
    main()
