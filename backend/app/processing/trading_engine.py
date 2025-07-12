import talib
import pandas as pd
import numpy as np
import yfinance as yf
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import warnings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Suppress yfinance warnings
warnings.filterwarnings("ignore", category=FutureWarning)

class TechnicalAnalyzer:
    """Advanced technical analysis engine for trading signals."""
    
    def __init__(self):
        self.min_data_points = 50  # Minimum data points for reliable analysis
    
    def calculate_indicators(self, prices: pd.DataFrame) -> Dict[str, Any]:
        """Calculate comprehensive technical indicators."""
        try:
            close = prices['close'].values
            high = prices['high'].values
            low = prices['low'].values
            volume = prices['volume'].values
            
            indicators = {}
            
            # Trend Indicators
            indicators['sma_20'] = talib.SMA(close, timeperiod=20)[-1] if len(close) >= 20 else None
            indicators['sma_50'] = talib.SMA(close, timeperiod=50)[-1] if len(close) >= 50 else None
            indicators['ema_12'] = talib.EMA(close, timeperiod=12)[-1] if len(close) >= 12 else None
            indicators['ema_26'] = talib.EMA(close, timeperiod=26)[-1] if len(close) >= 26 else None
            
            # Momentum Indicators
            indicators['rsi'] = talib.RSI(close, timeperiod=14)[-1] if len(close) >= 14 else None
            indicators['stoch_k'], indicators['stoch_d'] = talib.STOCH(high, low, close)[-2:] if len(close) >= 14 else (None, None)
            
            # MACD
            macd_line, macd_signal, macd_hist = talib.MACD(close, fastperiod=12, slowperiod=26, signalperiod=9)
            indicators['macd'] = macd_line[-1] if len(macd_line) > 0 else None
            indicators['macd_signal'] = macd_signal[-1] if len(macd_signal) > 0 else None
            indicators['macd_histogram'] = macd_hist[-1] if len(macd_hist) > 0 else None
            
            # Volatility Indicators
            indicators['atr'] = talib.ATR(high, low, close, timeperiod=14)[-1] if len(close) >= 14 else None
            
            # Bollinger Bands
            bb_upper, bb_middle, bb_lower = talib.BBANDS(close, timeperiod=20, nbdevup=2, nbdevdn=2, matype=0)
            indicators['bb_upper'] = bb_upper[-1] if len(bb_upper) > 0 else None
            indicators['bb_middle'] = bb_middle[-1] if len(bb_middle) > 0 else None
            indicators['bb_lower'] = bb_lower[-1] if len(bb_lower) > 0 else None
            
            # Volume Indicators
            indicators['volume_sma'] = talib.SMA(volume.astype(float), timeperiod=20)[-1] if len(volume) >= 20 else None
            
            # Price-based calculations
            current_price = close[-1]
            indicators['current_price'] = current_price
            
            # Support and Resistance levels
            recent_highs = pd.Series(high[-20:]).rolling(window=5).max()
            recent_lows = pd.Series(low[-20:]).rolling(window=5).min()
            indicators['resistance'] = recent_highs.max() if len(recent_highs) > 0 else None
            indicators['support'] = recent_lows.min() if len(recent_lows) > 0 else None
            
            return indicators
            
        except Exception as e:
            logger.error(f"Error calculating indicators: {str(e)}")
            return {}
    
    def analyze_trend(self, indicators: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze trend direction and strength."""
        trend_analysis = {
            'direction': 'neutral',
            'strength': 'weak',
            'signals': []
        }
        
        try:
            current_price = indicators.get('current_price')
            sma_20 = indicators.get('sma_20')
            sma_50 = indicators.get('sma_50')
            ema_12 = indicators.get('ema_12')
            ema_26 = indicators.get('ema_26')
            
            bullish_signals = 0
            bearish_signals = 0
            
            # Moving Average Analysis
            if current_price and sma_20:
                if current_price > sma_20:
                    bullish_signals += 1
                    trend_analysis['signals'].append("Price above SMA(20)")
                else:
                    bearish_signals += 1
                    trend_analysis['signals'].append("Price below SMA(20)")
            
            if sma_20 and sma_50:
                if sma_20 > sma_50:
                    bullish_signals += 1
                    trend_analysis['signals'].append("SMA(20) > SMA(50)")
                else:
                    bearish_signals += 1
                    trend_analysis['signals'].append("SMA(20) < SMA(50)")
            
            if ema_12 and ema_26:
                if ema_12 > ema_26:
                    bullish_signals += 1
                    trend_analysis['signals'].append("EMA(12) > EMA(26)")
                else:
                    bearish_signals += 1
                    trend_analysis['signals'].append("EMA(12) < EMA(26)")
            
            # Determine overall trend
            if bullish_signals > bearish_signals:
                trend_analysis['direction'] = 'bullish'
                trend_analysis['strength'] = 'strong' if bullish_signals >= 3 else 'moderate'
            elif bearish_signals > bullish_signals:
                trend_analysis['direction'] = 'bearish'
                trend_analysis['strength'] = 'strong' if bearish_signals >= 3 else 'moderate'
            
            return trend_analysis
            
        except Exception as e:
            logger.error(f"Error in trend analysis: {str(e)}")
            return trend_analysis
    
    def analyze_momentum(self, indicators: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze momentum indicators."""
        momentum_analysis = {
            'direction': 'neutral',
            'strength': 'weak',
            'signals': []
        }
        
        try:
            rsi = indicators.get('rsi')
            macd = indicators.get('macd')
            macd_signal = indicators.get('macd_signal')
            stoch_k = indicators.get('stoch_k')
            
            bullish_signals = 0
            bearish_signals = 0
            
            # RSI Analysis
            if rsi:
                if rsi < 30:
                    bullish_signals += 2  # Oversold - potential reversal
                    momentum_analysis['signals'].append(f"RSI oversold ({rsi:.1f})")
                elif rsi > 70:
                    bearish_signals += 2  # Overbought - potential reversal
                    momentum_analysis['signals'].append(f"RSI overbought ({rsi:.1f})")
                elif 40 <= rsi <= 60:
                    momentum_analysis['signals'].append(f"RSI neutral ({rsi:.1f})")
            
            # MACD Analysis
            if macd and macd_signal:
                if macd > macd_signal:
                    bullish_signals += 1
                    momentum_analysis['signals'].append("MACD bullish crossover")
                else:
                    bearish_signals += 1
                    momentum_analysis['signals'].append("MACD bearish crossover")
            
            # Stochastic Analysis
            if stoch_k:
                if stoch_k < 20:
                    bullish_signals += 1
                    momentum_analysis['signals'].append("Stochastic oversold")
                elif stoch_k > 80:
                    bearish_signals += 1
                    momentum_analysis['signals'].append("Stochastic overbought")
            
            # Determine momentum direction
            if bullish_signals > bearish_signals:
                momentum_analysis['direction'] = 'bullish'
                momentum_analysis['strength'] = 'strong' if bullish_signals >= 3 else 'moderate'
            elif bearish_signals > bullish_signals:
                momentum_analysis['direction'] = 'bearish'
                momentum_analysis['strength'] = 'strong' if bearish_signals >= 3 else 'moderate'
            
            return momentum_analysis
            
        except Exception as e:
            logger.error(f"Error in momentum analysis: {str(e)}")
            return momentum_analysis
    
    def analyze_volatility(self, indicators: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze volatility and support/resistance."""
        volatility_analysis = {
            'level': 'normal',
            'bb_position': 'middle',
            'signals': []
        }
        
        try:
            current_price = indicators.get('current_price')
            bb_upper = indicators.get('bb_upper')
            bb_middle = indicators.get('bb_middle')
            bb_lower = indicators.get('bb_lower')
            atr = indicators.get('atr')
            
            # Bollinger Bands Analysis
            if current_price and bb_upper and bb_lower and bb_middle:
                bb_width = (bb_upper - bb_lower) / bb_middle
                
                if bb_width > 0.1:
                    volatility_analysis['level'] = 'high'
                elif bb_width < 0.05:
                    volatility_analysis['level'] = 'low'
                
                # Position within bands
                if current_price >= bb_upper:
                    volatility_analysis['bb_position'] = 'upper'
                    volatility_analysis['signals'].append("Price at upper Bollinger Band")
                elif current_price <= bb_lower:
                    volatility_analysis['bb_position'] = 'lower'
                    volatility_analysis['signals'].append("Price at lower Bollinger Band")
                elif current_price > bb_middle:
                    volatility_analysis['bb_position'] = 'upper_middle'
                else:
                    volatility_analysis['bb_position'] = 'lower_middle'
            
            # ATR Analysis
            if atr and current_price:
                atr_percentage = (atr / current_price) * 100
                if atr_percentage > 3:
                    volatility_analysis['level'] = 'high'
                    volatility_analysis['signals'].append(f"High volatility (ATR: {atr_percentage:.1f}%)")
                elif atr_percentage < 1:
                    volatility_analysis['level'] = 'low'
                    volatility_analysis['signals'].append(f"Low volatility (ATR: {atr_percentage:.1f}%)")
            
            return volatility_analysis
            
        except Exception as e:
            logger.error(f"Error in volatility analysis: {str(e)}")
            return volatility_analysis

def get_historical_prices(asset: str, period: str = "3mo") -> Optional[pd.DataFrame]:
    """
    Fetch historical price data using yfinance.
    """
    try:
        # Clean asset symbol
        symbol = asset.upper().strip()
        if symbol == "UNKNOWN" or not symbol:
            return None
        
        # Fetch data from Yahoo Finance
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period=period)
        
        if hist.empty:
            logger.warning(f"No data found for symbol: {symbol}")
            return None
        
        # Standardize column names
        hist.columns = [col.lower() for col in hist.columns]
        
        # Ensure we have required columns
        required_cols = ['open', 'high', 'low', 'close', 'volume']
        if not all(col in hist.columns for col in required_cols):
            logger.error(f"Missing required columns for {symbol}")
            return None
        
        return hist[required_cols]
        
    except Exception as e:
        logger.error(f"Error fetching data for {asset}: {str(e)}")
        return None

def analyze_signal(signal) -> Dict[str, Any]:
    """
    Perform comprehensive technical and fundamental analysis on the signal's asset.
    Returns enhanced trade decision parameters with detailed reasoning.
    """
    try:
        # Fetch historical price data
        prices = get_historical_prices(signal.asset)
        
        if prices is None or len(prices) < 20:
            logger.warning(f"Insufficient data for {signal.asset}")
            return {
                "direction": "neutral",
                "entry_price": 0,
                "stop_loss": 0,
                "take_profit": 0,
                "confidence_score": 20,
                "position_size": 1.0,
                "risk_level": "high",
                "time_horizon": "intraday",
                "reasoning": f"Insufficient historical data for {signal.asset}",
                "technical_indicators": {},
                "analysis_summary": "Unable to perform technical analysis due to insufficient data"
            }
        
        # Initialize technical analyzer
        analyzer = TechnicalAnalyzer()
        
        # Calculate technical indicators
        indicators = analyzer.calculate_indicators(prices)
        
        # Perform analysis
        trend_analysis = analyzer.analyze_trend(indicators)
        momentum_analysis = analyzer.analyze_momentum(indicators)
        volatility_analysis = analyzer.analyze_volatility(indicators)
        
        # Determine overall direction
        direction = determine_trade_direction(trend_analysis, momentum_analysis, signal)
        
        # Calculate entry, stop loss, and take profit
        current_price = indicators.get('current_price', prices['close'].iloc[-1])
        atr = indicators.get('atr', current_price * 0.02)  # Default 2% if ATR unavailable
        
        entry_price = current_price
        
        # Dynamic stop loss and take profit based on volatility
        if direction == 'long':
            stop_loss = entry_price - (atr * 1.5)
            take_profit = entry_price + (atr * 3)
        elif direction == 'short':
            stop_loss = entry_price + (atr * 1.5)
            take_profit = entry_price - (atr * 3)
        else:  # neutral
            stop_loss = entry_price - (atr * 1)
            take_profit = entry_price + (atr * 1)
        
        # Calculate confidence score
        confidence_score = calculate_confidence_score(
            trend_analysis, momentum_analysis, volatility_analysis, signal
        )
        
        # Determine risk level
        risk_level = determine_risk_level(volatility_analysis, confidence_score)
        
        # Generate reasoning
        reasoning = generate_reasoning(
            trend_analysis, momentum_analysis, volatility_analysis, 
            direction, confidence_score
        )
        
        # Create analysis summary
        analysis_summary = create_analysis_summary(
            signal.asset, direction, confidence_score, 
            trend_analysis, momentum_analysis
        )
        
        return {
            "direction": direction,
            "entry_price": round(entry_price, 2),
            "stop_loss": round(stop_loss, 2),
            "take_profit": round(take_profit, 2),
            "confidence_score": confidence_score,
            "position_size": calculate_position_size(confidence_score, risk_level),
            "risk_level": risk_level,
            "time_horizon": signal.time_horizon if hasattr(signal, 'time_horizon') else "intraday",
            "reasoning": reasoning,
            "technical_indicators": indicators,
            "trend_analysis": trend_analysis,
            "momentum_analysis": momentum_analysis,
            "volatility_analysis": volatility_analysis,
            "analysis_summary": analysis_summary
        }
        
    except Exception as e:
        logger.error(f"Error in signal analysis: {str(e)}")
        return {
            "direction": "neutral",
            "entry_price": 0,
            "stop_loss": 0,
            "take_profit": 0,
            "confidence_score": 10,
            "position_size": 0.5,
            "risk_level": "high",
            "time_horizon": "intraday",
            "reasoning": f"Analysis failed due to error: {str(e)}",
            "technical_indicators": {},
            "analysis_summary": "Technical analysis unavailable due to system error"
        }

def determine_trade_direction(trend_analysis: Dict, momentum_analysis: Dict, signal) -> str:
    """Determine trade direction based on multiple factors."""
    
    # Weight different factors
    trend_weight = 0.4
    momentum_weight = 0.3
    news_weight = 0.3
    
    bullish_score = 0
    bearish_score = 0
    
    # Trend contribution
    if trend_analysis['direction'] == 'bullish':
        bullish_score += trend_weight * (2 if trend_analysis['strength'] == 'strong' else 1)
    elif trend_analysis['direction'] == 'bearish':
        bearish_score += trend_weight * (2 if trend_analysis['strength'] == 'strong' else 1)
    
    # Momentum contribution
    if momentum_analysis['direction'] == 'bullish':
        bullish_score += momentum_weight * (2 if momentum_analysis['strength'] == 'strong' else 1)
    elif momentum_analysis['direction'] == 'bearish':
        bearish_score += momentum_weight * (2 if momentum_analysis['strength'] == 'strong' else 1)
    
    # News sentiment contribution
    if hasattr(signal, 'direction'):
        if signal.direction == 'long':
            bullish_score += news_weight
        elif signal.direction == 'short':
            bearish_score += news_weight
    
    # Determine final direction
    if bullish_score > bearish_score and bullish_score > 0.6:
        return 'long'
    elif bearish_score > bullish_score and bearish_score > 0.6:
        return 'short'
    else:
        return 'neutral'

def calculate_confidence_score(trend_analysis: Dict, momentum_analysis: Dict, 
                             volatility_analysis: Dict, signal) -> int:
    """Calculate confidence score based on analysis confluence."""
    
    base_score = 50
    
    # Trend confidence
    if trend_analysis['strength'] == 'strong':
        base_score += 20
    elif trend_analysis['strength'] == 'moderate':
        base_score += 10
    
    # Momentum confidence
    if momentum_analysis['strength'] == 'strong':
        base_score += 15
    elif momentum_analysis['strength'] == 'moderate':
        base_score += 8
    
    # Volatility adjustment
    if volatility_analysis['level'] == 'high':
        base_score -= 10  # High volatility reduces confidence
    elif volatility_analysis['level'] == 'low':
        base_score += 5   # Low volatility increases confidence
    
    # News confidence boost
    if hasattr(signal, 'confidence_score') and signal.confidence_score:
        news_confidence = signal.confidence_score / 100
        base_score += int(news_confidence * 15)
    
    return max(10, min(100, base_score))

def determine_risk_level(volatility_analysis: Dict, confidence_score: int) -> str:
    """Determine risk level based on volatility and confidence."""
    
    if volatility_analysis['level'] == 'high' or confidence_score < 40:
        return 'high'
    elif volatility_analysis['level'] == 'low' and confidence_score > 70:
        return 'low'
    else:
        return 'medium'

def calculate_position_size(confidence_score: int, risk_level: str) -> float:
    """Calculate position size based on confidence and risk."""
    
    base_size = 2.0  # Base 2% of portfolio
    
    # Adjust for confidence
    confidence_multiplier = confidence_score / 100
    
    # Adjust for risk
    risk_multipliers = {'low': 1.5, 'medium': 1.0, 'high': 0.5}
    risk_multiplier = risk_multipliers.get(risk_level, 1.0)
    
    position_size = base_size * confidence_multiplier * risk_multiplier
    
    return round(max(0.5, min(10.0, position_size)), 1)

def generate_reasoning(trend_analysis: Dict, momentum_analysis: Dict, 
                     volatility_analysis: Dict, direction: str, confidence_score: int) -> str:
    """Generate human-readable reasoning for the trade decision."""
    
    reasoning_parts = []
    
    # Trend reasoning
    if trend_analysis['signals']:
        reasoning_parts.append(f"Trend Analysis: {trend_analysis['direction']} trend with {trend_analysis['strength']} strength. " + 
                             "; ".join(trend_analysis['signals'][:2]))
    
    # Momentum reasoning
    if momentum_analysis['signals']:
        reasoning_parts.append(f"Momentum Analysis: {momentum_analysis['direction']} momentum. " + 
                             "; ".join(momentum_analysis['signals'][:2]))
    
    # Volatility reasoning
    if volatility_analysis['signals']:
        reasoning_parts.append(f"Volatility: {volatility_analysis['level']} level. " + 
                             "; ".join(volatility_analysis['signals'][:1]))
    
    # Overall decision
    reasoning_parts.append(f"Overall Decision: {direction.upper()} with {confidence_score}% confidence based on technical confluence.")
    
    return " | ".join(reasoning_parts)

def create_analysis_summary(asset: str, direction: str, confidence_score: int, 
                          trend_analysis: Dict, momentum_analysis: Dict) -> str:
    """Create a concise analysis summary."""
    
    return (f"{asset}: {direction.upper()} signal with {confidence_score}% confidence. "
            f"Trend: {trend_analysis['direction']} ({trend_analysis['strength']}), "
            f"Momentum: {momentum_analysis['direction']} ({momentum_analysis['strength']})")
