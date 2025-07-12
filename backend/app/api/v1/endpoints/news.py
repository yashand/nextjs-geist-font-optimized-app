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

@router.get("/", response_model=List[models.News])
def read_news(skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    news_items = db.query(models.News).offset(skip).limit(limit).all()
    return news_items

@router.get("/{news_id}", response_model=models.News)
def read_news_item(news_id: int, db: Session = Depends(get_db)):
    news_item = db.query(models.News).filter(models.News.id == news_id).first()
    if news_item is None:
        raise HTTPException(status_code=404, detail="News item not found")
    return news_item
