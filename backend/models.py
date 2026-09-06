"""
SQLAlchemy ORM models for MandiSense.

Models:
  - Market: Agricultural market (mandi) with geolocation
  - CropPrice: Daily price record for a crop at a specific market
  - TransportRate: Vehicle type with per-km rate and capacity
"""

from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


class Market(Base):
    __tablename__ = "markets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    district = Column(String, nullable=False)
    state = Column(String, nullable=False, default="Karnataka")
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    # Relationship to crop prices
    prices = relationship("CropPrice", back_populates="market")

    def __repr__(self):
        return f"<Market(id={self.id}, name='{self.name}', district='{self.district}')>"


class CropPrice(Base):
    __tablename__ = "crop_prices"

    id = Column(Integer, primary_key=True, index=True)
    market_id = Column(Integer, ForeignKey("markets.id"), nullable=False)
    crop_name = Column(String, nullable=False)
    price_per_kg = Column(Float, nullable=False)
    date = Column(Date, nullable=False)
    arrival_volume_kg = Column(Float, nullable=True)

    # Relationship back to market
    market = relationship("Market", back_populates="prices")

    def __repr__(self):
        return (
            f"<CropPrice(market_id={self.market_id}, crop='{self.crop_name}', "
            f"price={self.price_per_kg}, date={self.date})>"
        )


class TransportRate(Base):
    __tablename__ = "transport_rates"

    id = Column(Integer, primary_key=True, index=True)
    vehicle_type = Column(String, nullable=False)
    rate_per_km = Column(Float, nullable=False)
    max_capacity_kg = Column(Float, nullable=False)
    base_fee = Column(Float, nullable=False)

    def __repr__(self):
        return (
            f"<TransportRate(type='{self.vehicle_type}', rate={self.rate_per_km}/km, "
            f"capacity={self.max_capacity_kg}kg)>"
        )
