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

@router.get("/", response_model=List[models.Signal])
def read_signals(skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    signals = db.query(models.Signal).offset(skip).limit(limit).all()
    return signals

@router.get("/{signal_id}", response_model=models.Signal)
def read_signal(signal_id: int, db: Session = Depends(get_db)):
    signal = db.query(models.Signal).filter(models.Signal.id == signal_id).first()
    if signal is None:
        raise HTTPException(status_code=404, detail="Signal not found")
    return signal
