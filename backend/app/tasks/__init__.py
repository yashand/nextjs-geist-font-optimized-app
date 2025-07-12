from celery import Celery
import os

celery_app = Celery(
    "app",
    broker=os.getenv("REDIS_URL", "redis://redis:6379/0"),
    backend=os.getenv("REDIS_URL", "redis://redis:6379/0"),
    include=[
        "app.tasks.news_tasks",
        "app.tasks.signal_tasks",
        "app.tasks.trade_tasks",
    ],
)

celery_app.conf.task_routes = {
    "app.tasks.news_tasks.*": {"queue": "news"},
    "app.tasks.signal_tasks.*": {"queue": "signals"},
    "app.tasks.trade_tasks.*": {"queue": "trades"},
}

celery_app.conf.task_default_queue = "default"
