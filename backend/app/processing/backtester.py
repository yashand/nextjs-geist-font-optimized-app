import pandas as pd
import yfinance as yf
import datetime
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class Backtester:
    """
    Backtesting module to evaluate trading signals using historical news and price data.
    """

    def __init__(self, start_date: str = "1923-01-01", end_date: Optional[str] = None):
        self.start_date = start_date
        self.end_date = end_date or datetime.datetime.today().strftime("%Y-%m-%d")

    def fetch_historical_prices(self, ticker: str) -> Optional[pd.DataFrame]:
        """
        Fetch historical price data for the given ticker from Yahoo Finance.
        """
        try:
            data = yf.download(ticker, start=self.start_date, end=self.end_date)
            if data.empty:
                logger.warning(f"No historical price data found for {ticker}")
                return None
            return data
        except Exception as e:
            logger.error(f"Error fetching historical prices for {ticker}: {e}")
            return None

    def backtest_signals(self, signals: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Backtest a list of signals against historical price data.
        Each signal should contain at least:
            - asset (ticker)
            - entry_date
            - direction ('long' or 'short')
            - entry_price
            - stop_loss
            - take_profit
            - time_horizon (days)
        Returns performance metrics including total return, win rate, max drawdown, and trade details.
        """
        results = []
        total_return = 0.0
        wins = 0
        losses = 0
        max_drawdown = 0.0

        for signal in signals:
            ticker = signal.get("asset")
            entry_date = signal.get("entry_date")
            direction = signal.get("direction")
            entry_price = signal.get("entry_price")
            stop_loss = signal.get("stop_loss")
            take_profit = signal.get("take_profit")
            time_horizon = signal.get("time_horizon", 1)

            if not ticker or not entry_date or not direction or not entry_price:
                logger.warning(f"Skipping incomplete signal: {signal}")
                continue

            price_data = self.fetch_historical_prices(ticker)
            if price_data is None:
                continue

            # Filter price data from entry_date to entry_date + time_horizon
            try:
                start = pd.to_datetime(entry_date)
                end = start + pd.Timedelta(days=time_horizon)
                price_slice = price_data.loc[start:end]
            except Exception as e:
                logger.error(f"Error slicing price data for {ticker}: {e}")
                continue

            if price_slice.empty:
                logger.warning(f"No price data in backtest window for {ticker} from {start} to {end}")
                continue

            # Simulate trade outcome
            trade_result = self.simulate_trade(price_slice, direction, entry_price, stop_loss, take_profit)
            results.append(trade_result)

            total_return += trade_result["return_pct"]
            if trade_result["return_pct"] > 0:
                wins += 1
            else:
                losses += 1

            max_drawdown = min(max_drawdown, trade_result.get("max_drawdown", 0))

        total_trades = wins + losses
        win_rate = (wins / total_trades) * 100 if total_trades > 0 else 0
        avg_return = total_return / total_trades if total_trades > 0 else 0

        performance = {
            "total_trades": total_trades,
            "wins": wins,
            "losses": losses,
            "win_rate": win_rate,
            "average_return_pct": avg_return,
            "max_drawdown_pct": max_drawdown,
            "trade_details": results
        }

        return performance

    def simulate_trade(self, price_data: pd.DataFrame, direction: str, entry_price: float,
                       stop_loss: float, take_profit: float) -> Dict[str, Any]:
        """
        Simulate a single trade given price data and trade parameters.
        Returns trade outcome including return percentage and max drawdown.
        """
        max_drawdown = 0.0
        peak_price = entry_price
        exit_price = entry_price
        exit_reason = "time_horizon_end"

        for idx, row in price_data.iterrows():
            high = row["High"]
            low = row["Low"]
            close = row["Close"]

            if direction == "long":
                # Check stop loss
                if low <= stop_loss:
                    exit_price = stop_loss
                    exit_reason = "stop_loss"
                    break
                # Check take profit
                if high >= take_profit:
                    exit_price = take_profit
                    exit_reason = "take_profit"
                    break
                # Track peak for drawdown
                peak_price = max(peak_price, high)
                drawdown = (peak_price - low) / peak_price
                max_drawdown = min(max_drawdown, -drawdown)
            else:
                # Short position
                if high >= stop_loss:
                    exit_price = stop_loss
                    exit_reason = "stop_loss"
                    break
                if low <= take_profit:
                    exit_price = take_profit
                    exit_reason = "take_profit"
                    break
                peak_price = min(peak_price, low)
                drawdown = (low - peak_price) / peak_price
                max_drawdown = min(max_drawdown, -drawdown)

        if direction == "long":
            return_pct = (exit_price - entry_price) / entry_price * 100
        else:
            return_pct = (entry_price - exit_price) / entry_price * 100

        return {
            "exit_price": exit_price,
            "exit_reason": exit_reason,
            "return_pct": return_pct,
            "max_drawdown": max_drawdown,
            "direction": direction,
            "entry_price": entry_price,
            "stop_loss": stop_loss,
            "take_profit": take_profit,
            "trade_length_days": len(price_data)
        }
