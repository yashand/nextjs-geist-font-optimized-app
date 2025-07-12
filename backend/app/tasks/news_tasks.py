from app.tasks import celery_app
from app.db import database, models
from sqlalchemy.orm import Session
import httpx
import os

@celery_app.task(name="fetch_news")
def fetch_news_task():
    # Example: Fetch news from a news API (replace with actual API and keys)
    api_key = os.getenv("NEWS_API_KEY")
    url = f"https://newsapi.org/v2/top-headlines?category=business&apiKey={api_key}"
    response = httpx.get(url)
    news_items = response.json().get("articles", [])

    db: Session = database.SessionLocal()
    try:
        for item in news_items:
            news = models.News(
                source=item.get("source", {}).get("name", ""),
                headline=item.get("title", ""),
                content=item.get("description", ""),
                sentiment_score=0.0,  # To be processed
                impact_rating=0.0,    # To be processed
                timestamp=item.get("publishedAt"),
                language=item.get("language", "en"),
                processed=False,
            )
            db.add(news)
        db.commit()
    finally:
        db.close()
