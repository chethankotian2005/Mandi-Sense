"""
Quick diagnostic script to inspect seeded data in the MandiSense database.
Prints markets, recent tomato prices, and transport rates.
"""

import sys
from pathlib import Path

# Add parent directory to path so we can import backend modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from datetime import date, timedelta
from sqlalchemy import desc
from database import SessionLocal
from models import Market, CropPrice, TransportRate


def check():
    db = SessionLocal()

    try:
        # ── Markets ──────────────────────────────────────────────
        print("=" * 60)
        print("MARKETS")
        print("=" * 60)
        markets = db.query(Market).all()
        for m in markets:
            print(
                f"  [{m.id}] {m.name} - {m.district}, {m.state}  "
                f"({m.latitude:.4f}, {m.longitude:.4f})"
            )

        # ── Tomato Prices (last 5 days) ─────────────────────────
        print()
        print("=" * 60)
        print("TOMATO PRICES - Last 5 Days")
        print("=" * 60)
        cutoff = date.today() - timedelta(days=4)
        for m in markets:
            print(f"\n  {m.name}:")
            prices = (
                db.query(CropPrice)
                .filter(
                    CropPrice.market_id == m.id,
                    CropPrice.crop_name == "Tomato",
                    CropPrice.date >= cutoff,
                )
                .order_by(desc(CropPrice.date))
                .all()
            )
            for p in prices:
                vol = f"{p.arrival_volume_kg:.0f} kg" if p.arrival_volume_kg else "N/A"
                print(f"    {p.date}  Rs.{p.price_per_kg:>6.2f}/kg   arrival: {vol}")

        # ── Transport Rates ──────────────────────────────────────
        print()
        print("=" * 60)
        print("TRANSPORT RATES")
        print("=" * 60)
        rates = db.query(TransportRate).all()
        for r in rates:
            print(
                f"  {r.vehicle_type:>12s}  - Rs.{r.rate_per_km:.1f}/km  "
                f"capacity: {r.max_capacity_kg:.0f} kg  base fee: Rs.{r.base_fee:.0f}"
            )

    finally:
        db.close()


if __name__ == "__main__":
    check()
