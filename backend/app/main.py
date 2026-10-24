"""FastAPI application entry point.

Production use:  uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
Development:      uvicorn backend.app.main:app --reload

The app is intentionally read-only.  No POST/PUT/DELETE/PATCH routes are
defined in this MVP foundation.
"""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Local imports to keep startup cheap
from .routes import health, products, production, organic, wilayah, sales, forecasts

app = FastAPI(
    title="Vinix7 API",
    description=(
        "Read-only API for the Sistem Data Terintegrasi Desa Cangkringan. "
        "Provides access to product catalog, production, sales, organic material "
        "availability, and analytical results."
    ),
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
# PRD §7: limit CORS to allowed domains via environment variable.
# For MVP development we default to a safe permissive setting that can be
# overridden via the CORS_ORIGINS environment variable.
import os

_allow_origins = os.getenv("CORS_ORIGINS", "").strip()
if not _allow_origins:
    _origins = ["http://localhost:5173", "http://localhost:3000"]  # dev defaults
else:
    _origins = [o.strip() for o in _allow_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(products.router)
app.include_router(production.router)
app.include_router(organic.router)
app.include_router(wilayah.router)
app.include_router(sales.router)
app.include_router(forecasts.router)


@app.get("/", include_in_schema=False)
def root() -> dict[str, str]:
    return {"message": "Vinix7 API is running. See /docs for the interactive documentation."}


@app.exception_handler(Exception)
def global_exception_handler(request, exc: Exception):
    """Catch-all handler — never leak stack traces or credentials."""
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal error occurred. Please try again later."},
    )
