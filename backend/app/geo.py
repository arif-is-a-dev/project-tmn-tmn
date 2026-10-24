"""Geospatial utility functions for VINIX7.

Pure functions with no database or network dependencies.
Designed to be independently testable without any external state.

Haversine formula computes great-circle distance between two points
on Earth's surface given latitude/longitude in decimal degrees.
"""

from __future__ import annotations

import math
from typing import Optional


# Mean Earth radius in kilometers (WGS-84 volumetric mean).
# Sufficient precision for distances within a single kecamatan (~10 km scale).
EARTH_RADIUS_KM = 6371.0


def haversine(
    lat1: Optional[float],
    lon1: Optional[float],
    lat2: Optional[float],
    lon2: Optional[float],
) -> Optional[float]:
    """Compute great-circle distance in km between two geographic points.

    Uses the Haversine formula:
        a = sin²(Δlat/2) + cos(lat1) · cos(lat2) · sin²(Δlon/2)
        c = 2 · atan2(√a, √(1−a))
        d = R · c

    Parameters
    ----------
    lat1, lon1 : float or None
        Latitude and longitude of point 1 in decimal degrees.
    lat2, lon2 : float or None
        Latitude and longitude of point 2 in decimal degrees.

    Returns
    -------
    float or None
        Distance in kilometers, rounded to 4 decimal places.
        Returns None if ANY input coordinate is None.

    Raises
    ------
    ValueError
        If any coordinate is outside valid range:
        latitude must be in [-90, 90], longitude in [-180, 180].

    Examples
    --------
    >>> haversine(-7.6588, 110.4563, -7.6588, 110.4563)
    0.0
    >>> round(haversine(-7.7972, 110.3688, -7.6588, 110.4563), 2)
    17.47
    """
    # NULL guard: if any coordinate is missing, distance cannot be computed
    if lat1 is None or lon1 is None or lat2 is None or lon2 is None:
        return None

    # Validate coordinate ranges
    if not (-90 <= lat1 <= 90):
        raise ValueError(f"lat1={lat1} out of range [-90, 90]")
    if not (-90 <= lat2 <= 90):
        raise ValueError(f"lat2={lat2} out of range [-90, 90]")
    if not (-180 <= lon1 <= 180):
        raise ValueError(f"lon1={lon1} out of range [-180, 180]")
    if not (-180 <= lon2 <= 180):
        raise ValueError(f"lon2={lon2} out of range [-180, 180]")

    # Convert to radians
    φ1 = math.radians(lat1)
    φ2 = math.radians(lat2)
    Δφ = math.radians(lat2 - lat1)
    Δλ = math.radians(lon2 - lon1)

    # Haversine formula
    a = (math.sin(Δφ / 2) ** 2
         + math.cos(φ1) * math.cos(φ2) * math.sin(Δλ / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance_km = EARTH_RADIUS_KM * c
    return round(distance_km, 4)
