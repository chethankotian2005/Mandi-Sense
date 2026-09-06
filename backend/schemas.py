"""
Pydantic models for API request/response validation.
"""

from typing import Optional
from pydantic import BaseModel, Field


class CompareRequest(BaseModel):
    """Request body for POST /api/compare."""
    crop_name: str
    quantity_kg: float
    farmer_latitude: float
    farmer_longitude: float
    radius_km: float = Field(default=50.0, description="Search radius in km")
    target_market_name: Optional[str] = None


class MarketResult(BaseModel):
    """A single market comparison result."""
    market_name: str
    latitude: float
    longitude: float
    distance_km: float
    current_price_per_kg: float
    trend: str  # "rising", "falling", or "stable"
    transport_cost: float
    net_return: float
    rationale: str


from typing import Optional

class CompareResponse(BaseModel):
    """Response for POST /api/compare."""
    crop_name: str
    quantity_kg: float
    results: list[MarketResult]
    best_market_name: Optional[str] = None
    net_return_difference: Optional[float] = None
    trend: Optional[str] = None


class CropsResponse(BaseModel):
    """Response for GET /api/crops."""
    crops: list[str]


class HealthResponse(BaseModel):
    """Response for GET /api/health."""
    status: str
    database: str


class DecisionTimingResponse(BaseModel):
    """Response for POST /api/decision-timing."""
    today_net_return: float
    projected_net_return_in_2_days: float
    recommendation: str
    rationale_key: str
    gain_percent: float
