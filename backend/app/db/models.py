from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class News(Base):
    __tablename__ = "news"

    id = Column(Integer, primary_key=True, index=True)
    source = Column(String, index=True)
    headline = Column(String)
    content = Column(String)
    sentiment_score = Column(Float)
    impact_rating = Column(Float)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    language = Column(String, default="en")
    processed = Column(Boolean, default=False)

    signals = relationship("Signal", back_populates="news")

class Signal(Base):
    __tablename__ = "signals"

    id = Column(Integer, primary_key=True, index=True)
    news_id = Column(Integer, ForeignKey("news.id"))
    asset = Column(String, index=True)
    direction = Column(String)  # 'long', 'short', 'neutral'
    entry_price = Column(Float)
    stop_loss = Column(Float)
    take_profit = Column(Float)
    confidence_score = Column(Float)
    position_size = Column(Float)  # as a percentage of portfolio
    risk_level = Column(String)    # 'low', 'medium', 'high'
    time_horizon = Column(String)  # 'intraday', '2_days', '1_week', '1_month'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    news = relationship("News", back_populates="signals")
    trades = relationship("Trade", back_populates="signal")

class Trade(Base):
    __tablename__ = "trades"

    id = Column(Integer, primary_key=True, index=True)
    signal_id = Column(Integer, ForeignKey("signals.id"))
    executed_price = Column(Float)
    quantity = Column(Float)
    status = Column(String)  # 'executed', 'canceled', 'pending'
    executed_at = Column(DateTime, default=datetime.datetime.utcnow)

    signal = relationship("Signal", back_populates="trades")
