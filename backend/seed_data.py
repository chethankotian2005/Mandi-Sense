"""
Seed script for MandiSense database.

Populates:
  - 4 markets in the Udupi-Mangalore coastal belt (Karnataka)
  - 14 days of price data for Tomato and Onion per market
  - 2 transport vehicle types (mini_truck, tempo)

Price data includes realistic day-to-day noise plus a directional trend
per market.  Trends are amplified enough that the API trend detection
reliably labels at least one market "rising" and one "falling" -- this
makes the hackathon demo visually compelling.
"""

import random
import sys
from datetime import date, timedelta

from database import Base, engine, SessionLocal
from models import Market, CropPrice, TransportRate


def seed():
    # Create all tables (drops existing if any)
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        # -- Markets --------------------------------------------------------
        # Real locations in the coastal Karnataka ~50 km cluster
        markets = [
            Market(
                name="Udupi APMC",
                district="Udupi",
                state="Karnataka",
                latitude=13.3409,
                longitude=74.7421,
            ),
            Market(
                name="Mangalore APMC",
                district="Dakshina Kannada",
                state="Karnataka",
                latitude=12.9141,
                longitude=74.8560,
            ),
            Market(
                name="Kundapura Market",
                district="Udupi",
                state="Karnataka",
                latitude=13.6200,
                longitude=74.6944,
            ),
            Market(
                name="Karkala Market",
                district="Udupi",
                state="Karnataka",
                latitude=13.2130,
                longitude=74.9900,
            ),
        ]
        db.add_all(markets)
        db.flush()  # Assign IDs

        # -- Crop Prices ----------------------------------------------------
        # Base prices (Rs/kg) and per-market trend direction.
        # Trends are amplified so the 7-day window reliably crosses the
        # +/-2 % threshold used by compute_trend().
        crop_configs = {
            "Tomato": {
                "base_prices": {
                    "Udupi APMC": 30.0,
                    "Mangalore APMC": 38.0,       # starts high, falls
                    "Kundapura Market": 28.0,
                    "Karkala Market": 26.0,
                },
                "trends": {
                    "Udupi APMC": +0.55,          # clearly rising
                    "Mangalore APMC": -0.45,       # clearly falling
                    "Kundapura Market": +0.20,     # mildly rising
                    "Karkala Market": +0.02,       # flat / stable
                },
            },
            "Onion": {
                "base_prices": {
                    "Udupi APMC": 22.0,
                    "Mangalore APMC": 25.0,
                    "Kundapura Market": 20.0,
                    "Karkala Market": 18.0,
                },
                "trends": {
                    "Udupi APMC": -0.35,           # falling
                    "Mangalore APMC": +0.40,        # rising
                    "Kundapura Market": -0.10,      # mildly falling
                    "Karkala Market": +0.50,        # clearly rising
                },
            },
        }

        today = date.today()
        start_date = today - timedelta(days=13)  # 14 days including today

        random.seed(42)  # Reproducible

        price_records = []
        for crop_name, config in crop_configs.items():
            for market in markets:
                base = config["base_prices"][market.name]
                daily_trend = config["trends"][market.name]

                for day_offset in range(14):
                    d = start_date + timedelta(days=day_offset)
                    # Price = base + trend * day + random noise (+/-3%)
                    trend_component = daily_trend * day_offset
                    noise = random.uniform(-0.03, 0.03) * base
                    price = round(max(5.0, base + trend_component + noise), 2)

                    # Arrival volume: 500-5000 kg with some randomness
                    volume = round(random.uniform(500, 5000), 0)

                    price_records.append(
                        CropPrice(
                            market_id=market.id,
                            crop_name=crop_name,
                            price_per_kg=price,
                            date=d,
                            arrival_volume_kg=volume,
                        )
                    )

        db.add_all(price_records)

        # -- Transport Rates ------------------------------------------------
        transport_rates = [
            TransportRate(
                vehicle_type="mini_truck",
                rate_per_km=12.0,
                max_capacity_kg=2000.0,
                base_fee=200.0,
            ),
            TransportRate(
                vehicle_type="tempo",
                rate_per_km=8.0,
                max_capacity_kg=800.0,
                base_fee=150.0,
            ),
        ]
        db.add_all(transport_rates)

        db.commit()

        # -- Summary --------------------------------------------------------
        market_count = db.query(Market).count()
        price_count = db.query(CropPrice).count()
        transport_count = db.query(TransportRate).count()

        print(f"[OK] Seeded successfully!")
        print(f"   Markets:         {market_count}")
        print(f"   Crop prices:     {price_count}")
        print(f"   Transport rates: {transport_count}")

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Seed failed: {e}", file=sys.stderr)
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
