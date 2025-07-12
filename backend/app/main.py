from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import news, signals, trades, websocket, backtest

app = FastAPI(title="Real-Time Financial Trading Assistant")

app.include_router(news.router, prefix="/api/v1/news", tags=["news"])
app.include_router(signals.router, prefix="/api/v1/signals", tags=["signals"])
app.include_router(trades.router, prefix="/api/v1/trades", tags=["trades"])
app.include_router(backtest.router, prefix="/api/v1/backtest", tags=["backtest"])

@app.get("/")
async def root():
    return {"message": "Welcome to the Real-Time Financial Trading Assistant API"}
