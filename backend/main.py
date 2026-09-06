"""
MandiSense FastAPI application.

Endpoints:
  POST /api/compare  — Compare markets for a crop, sorted by net return
  GET  /api/crops    — List available crop names
  GET  /api/health   — Health check
"""

import math
from datetime import date, timedelta

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from database import get_db, engine, Base
from models import Market, CropPrice, TransportRate
from schemas import (
    CompareRequest,
    CompareResponse,
    MarketResult,
    CropsResponse,
    HealthResponse,
    DecisionTimingResponse,
)

# ── Create tables if they don't exist ──────────────────────────────
Base.metadata.create_all(bind=engine)

# ── App setup ──────────────────────────────────────────────────────
app = FastAPI(
    title="MandiSense API",
    description="Crop market comparison and price intelligence for farmers",
    version="0.1.0",
)

# CORS — allow all origins (hackathon demo)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Haversine helper ───────────────────────────────────────────────

def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great-circle distance between two points on Earth
    using the haversine formula.  Returns distance in kilometres.
    """
    R = 6371.0  # Earth's mean radius in km

    lat1_r, lon1_r = math.radians(lat1), math.radians(lon1)
    lat2_r, lon2_r = math.radians(lat2), math.radians(lon2)

    dlat = lat2_r - lat1_r
    dlon = lon2_r - lon1_r

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1_r) * math.cos(lat2_r) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


# ── Trend detection ────────────────────────────────────────────────

TREND_THRESHOLD = 0.02  # ±2%


def compute_trend(prices_last_7: list[float]) -> str:
    """
    Compare the average of the most recent 3 days vs the 4 days before that.
    Returns 'rising', 'falling', or 'stable'.

    prices_last_7 should be ordered oldest → newest, length ≥ 7.
    """
    if len(prices_last_7) < 7:
        return "stable"  # not enough data

    older_avg = sum(prices_last_7[:4]) / 4
    recent_avg = sum(prices_last_7[4:]) / 3

    if older_avg == 0:
        return "stable"

    change = (recent_avg - older_avg) / older_avg

    if change > TREND_THRESHOLD:
        return "rising"
    elif change < -TREND_THRESHOLD:
        return "falling"
    return "stable"


# ── Transport cost ─────────────────────────────────────────────────

def compute_transport(
    quantity_kg: float,
    distance_km: float,
    rates: list[TransportRate],
) -> tuple[float, str | None]:
    """
    Pick the cheapest vehicle that can carry quantity_kg.
    Returns (cost, note).  Note is set if multiple trips are required.
    """
    # Sort by capacity ascending so we pick the smallest vehicle that fits
    sorted_rates = sorted(rates, key=lambda r: r.max_capacity_kg)

    note = None
    chosen = None

    for rate in sorted_rates:
        if rate.max_capacity_kg >= quantity_kg:
            chosen = rate
            break

    if chosen is None:
        # Largest vehicle still can't carry the full load
        chosen = sorted_rates[-1]  # use the biggest
        note = "requires multiple trips"

    cost = chosen.base_fee + (chosen.rate_per_km * distance_km)
    return round(cost, 2), note


# ── Endpoints ──────────────────────────────────────────────────────

@app.post("/api/compare", response_model=CompareResponse)
def compare_markets(req: CompareRequest, db: Session = Depends(get_db)):
    """
    Compare nearby markets for a given crop, returning results sorted
    by net return (descending).
    """
    # 1. Find all markets within radius
    all_markets = db.query(Market).all()
    nearby: list[tuple[Market, float]] = []
    for m in all_markets:
        dist = haversine_km(req.farmer_latitude, req.farmer_longitude, m.latitude, m.longitude)
        if dist <= req.radius_km:
            nearby.append((m, round(dist, 2)))

    if not nearby:
        raise HTTPException(status_code=404, detail="No markets found within the specified radius.")

    # Load transport rates once
    transport_rates = db.query(TransportRate).all()
    if not transport_rates:
        raise HTTPException(status_code=500, detail="No transport rates configured.")

    today = date.today()
    results: list[MarketResult] = []

    for market, distance_km in nearby:
        # 2. Latest price
        latest_price_row = (
            db.query(CropPrice)
            .filter(
                CropPrice.market_id == market.id,
                CropPrice.crop_name == req.crop_name,
            )
            .order_by(desc(CropPrice.date))
            .first()
        )
        if latest_price_row is None:
            continue  # No price data for this crop at this market

        current_price = latest_price_row.price_per_kg

        # 3. Trend: get last 7 days of prices (oldest → newest)
        seven_days_ago = today - timedelta(days=6)
        week_prices = (
            db.query(CropPrice.price_per_kg)
            .filter(
                CropPrice.market_id == market.id,
                CropPrice.crop_name == req.crop_name,
                CropPrice.date >= seven_days_ago,
            )
            .order_by(CropPrice.date)
            .all()
        )
        price_list = [row[0] for row in week_prices]
        trend = compute_trend(price_list)

        # 4. Transport cost
        transport_cost, transport_note = compute_transport(
            req.quantity_kg, distance_km, transport_rates
        )

        # 5. Net return
        net_return = round((current_price * req.quantity_kg) - transport_cost, 2)

        results.append(
            MarketResult(
                market_name=market.name,
                latitude=market.latitude,
                longitude=market.longitude,
                distance_km=distance_km,
                current_price_per_kg=current_price,
                trend=trend,
                transport_cost=transport_cost,
                net_return=net_return,
                rationale="",  # filled below after sorting
            )
        )

    # 6. Sort by net_return descending
    results.sort(key=lambda r: r.net_return, reverse=True)

    # Generate rationales
    for i, r in enumerate(results):
        if i == 0 and len(results) > 1:
            diff = round(r.net_return - results[1].net_return, 2)
            r.rationale = (
                f"Best option — ₹{diff:.0f} higher net return than the next best market, "
                f"and price has been {r.trend} this week."
            )
        elif i == 0:
            r.rationale = (
                f"Only market in range. Price has been {r.trend} this week."
            )
        else:
            diff = round(results[0].net_return - r.net_return, 2)
            r.rationale = (
                f"₹{diff:.0f} less net return than the best option. "
                f"Price has been {r.trend} this week."
            )

    best_market_name = None
    net_return_difference = None
    top_trend = None

    if results:
        best_market_name = results[0].market_name
        top_trend = results[0].trend
        if len(results) > 1:
            net_return_difference = round(results[0].net_return - results[1].net_return, 2)
        else:
            net_return_difference = 0.0

    return CompareResponse(
        crop_name=req.crop_name,
        quantity_kg=req.quantity_kg,
        results=results,
        best_market_name=best_market_name,
        net_return_difference=net_return_difference,
        trend=top_trend,
    )


@app.post("/api/decision-timing", response_model=DecisionTimingResponse)
def decision_timing(req: CompareRequest, db: Session = Depends(get_db)):
    """
    Project the net return 2 days ahead for a specific market (or the top-recommended market if none specified).
    """
    all_markets = db.query(Market).all()
    nearby = []
    for m in all_markets:
        dist = haversine_km(req.farmer_latitude, req.farmer_longitude, m.latitude, m.longitude)
        if dist <= req.radius_km:
            nearby.append((m, dist))

    if not nearby:
        raise HTTPException(status_code=404, detail="No markets found within the specified radius.")

    transport_rates = db.query(TransportRate).all()
    if not transport_rates:
        raise HTTPException(status_code=500, detail="No transport rates configured.")

    today = date.today()
    
    best_market = None
    best_net_return = -1.0
    best_current_price = 0.0
    best_transport_cost = 0.0

    for market, distance_km in nearby:
        latest_price_row = (
            db.query(CropPrice)
            .filter(
                CropPrice.market_id == market.id,
                CropPrice.crop_name == req.crop_name,
            )
            .order_by(desc(CropPrice.date))
            .first()
        )
        if latest_price_row is None:
            continue
            
        current_price = latest_price_row.price_per_kg
        transport_cost, _ = compute_transport(req.quantity_kg, distance_km, transport_rates)
        net_return = round((current_price * req.quantity_kg) - transport_cost, 2)
        
        if req.target_market_name:
            if market.name == req.target_market_name:
                best_net_return = net_return
                best_market = market
                best_current_price = current_price
                best_transport_cost = transport_cost
                break
        else:
            if net_return > best_net_return:
                best_net_return = net_return
                best_market = market
                best_current_price = current_price
                best_transport_cost = transport_cost

    if best_market is None:
        raise HTTPException(status_code=404, detail="No price data found for nearby markets.")

    seven_days_ago = today - timedelta(days=6)
    week_prices = (
        db.query(CropPrice.price_per_kg)
        .filter(
            CropPrice.market_id == best_market.id,
            CropPrice.crop_name == req.crop_name,
            CropPrice.date >= seven_days_ago,
        )
        .order_by(CropPrice.date)
        .all()
    )
    
    price_list = [row[0] for row in week_prices]
    trend = compute_trend(price_list)
    
    if len(price_list) > 1:
        slope = (price_list[-1] - price_list[0]) / (len(price_list) - 1)
    else:
        slope = 0.0
        
    projected_price = best_current_price + (slope * 2)
    projected_net_return = round((projected_price * req.quantity_kg) - best_transport_cost, 2)
    
    if best_net_return >= projected_net_return or trend in ["falling", "stable"]:
        recommendation = "sell_now"
        gain_percent = 0.0
        if trend == "falling":
            rationale_key = "rationale_falling"
        else:
            rationale_key = "rationale_stable"
    else:
        gain = (projected_net_return - best_net_return) / best_net_return if best_net_return > 0 else 0
        gain_percent = round(gain * 100, 1)
        if gain > 0.05 and trend == "rising":
            recommendation = "wait_2_days"
            rationale_key = "rationale_wait"
        else:
            recommendation = "sell_now"
            rationale_key = "rationale_small_gain"
            
    return DecisionTimingResponse(
        today_net_return=best_net_return,
        projected_net_return_in_2_days=projected_net_return,
        recommendation=recommendation,
        rationale_key=rationale_key,
        gain_percent=gain_percent
    )


@app.get("/api/crops", response_model=CropsResponse)
def list_crops(db: Session = Depends(get_db)):
    """Return the list of distinct crop names available in the database."""
    rows = db.query(CropPrice.crop_name).distinct().all()
    crops = sorted([row[0] for row in rows])
    return CropsResponse(crops=crops)


@app.get("/api/health", response_model=HealthResponse)
def health_check(db: Session = Depends(get_db)):
    """Basic health check — verifies the database is reachable."""
    try:
        db.execute(func.now() if False else db.query(Market).limit(1).statement)
        db_status = "connected"
    except Exception:
        db_status = "error"
    return HealthResponse(status="ok", database=db_status)


# ── Coming Soon Stubs (Week 2/3 Features) ─────────────────────────

@app.get("/api/forecast/{crop_name}/{market_id}")
def price_forecast(crop_name: str, market_id: int):
    """Stub: Short-horizon ML price prediction (coming in Week 2)."""
    return {"status": "coming_soon", "feature": "price_forecast"}


@app.get("/api/pooling/estimate")
def transport_pooling():
    """Stub: Transport cost-sharing with nearby farmers (coming in Week 2)."""
    return {"status": "coming_soon", "feature": "transport_pooling"}


@app.get("/api/spoilage-adjusted-return")
def spoilage_adjusted_return():
    """Stub: Spoilage-adjusted net return calculation (coming in Week 3)."""
    return {"status": "coming_soon", "feature": "spoilage_adjustment"}
