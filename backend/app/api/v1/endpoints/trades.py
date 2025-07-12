from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import models, database
from typing import List

router = APIRouter()

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/", response_model=List[models.Trade])
def read_trades(skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    trades = db.query(models.Trade).offset(skip).limit(limit).all()
    return trades

@router.get("/{trade_id}", response_model=models.Trade)
def read_trade(trade_id: int, db: Session = Depends(get_db)):
    trade = db.query(models.Trade).filter(models.Trade.id == trade_id).first()
    if trade is None:
        raise HTTPException(status_code=404, detail="Trade not found")
    return trade
