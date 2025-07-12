from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from backend.app.db import database, models
from backend.app.processing.backtester import Backtester
import logging

router = APIRouter()

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/backtest", summary="Run backtest on historical signals")
def run_backtest(db: Session = Depends(get_db)):
    """
    Run backtest on historical signals stored in the database.
    Returns accuracy metrics and detailed trade results.
    """
    try:
        # Fetch signals with required fields
        signals = db.query(models.Signal).all()
        if not signals:
            raise HTTPException(status_code=404, detail="No signals found for backtesting")

        # Prepare signals data for backtester
        signals_data = []
        for signal in signals:
            signals_data.append({
                "asset": signal.asset,
                "entry_date": signal.created_at.strftime("%Y-%m-%d") if signal.created_at else None,
                "direction": signal.direction,
                "entry_price": signal.entry_price,
                "stop_loss": signal.stop_loss,
                "take_profit": signal.take_profit,
                "time_horizon": 30  # default 30 days for backtest
            })

        backtester = Backtester()
        performance = backtester.backtest_signals(signals_data)

        return performance

    except Exception as e:
        logging.error(f"Backtest API error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")
