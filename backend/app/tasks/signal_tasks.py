from app.tasks import celery_app
from app.db import database, models
from sqlalchemy.orm import Session
from app.processing.news_processor import process_news_item
from app.processing.trading_engine import analyze_signal
from app.processing.risk_management import AdvancedRiskManager
from app.api.v1.endpoints.websocket import broadcast_message
import asyncio
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@celery_app.task(name="process_news")
def process_news_task():
    """Enhanced news processing task with LLM integration."""
    db: Session = database.SessionLocal()
    try:
        unprocessed_news = db.query(models.News).filter(models.News.processed == False).all()
        logger.info(f"Processing {len(unprocessed_news)} unprocessed news items")
        
        for news_item in unprocessed_news:
            try:
                # Process news item with enhanced analysis
                processed_data = asyncio.run(process_news_item(news_item))
                
                # Update news item with processed data
                news_item.sentiment_score = processed_data.get("sentiment_score", 0.0)
                news_item.impact_rating = processed_data.get("impact_rating", 0.0)
                news_item.processed = True
                
                # Store additional analysis data as JSON
                analysis_metadata = {
                    "sector": processed_data.get("sector", "general"),
                    "extracted_tickers": processed_data.get("extracted_tickers", []),
                    "analysis_summary": processed_data.get("analysis_summary", ""),
                    "event_type": processed_data.get("event_type", "other"),
                    "market_impact": processed_data.get("market_impact", "medium"),
                    "reasoning": processed_data.get("reasoning", "")
                }
                
                # Store metadata in content field (you might want to add a JSON field to the model)
                if news_item.content:
                    news_item.content = news_item.content + f"\n\nANALYSIS_METADATA: {json.dumps(analysis_metadata)}"
                else:
                    news_item.content = f"ANALYSIS_METADATA: {json.dumps(analysis_metadata)}"
                
                db.add(news_item)
                db.commit()
                
                # Create signal if actionable
                if processed_data.get("actionable", False):
                    signal = models.Signal(
                        news_id=news_item.id,
                        asset=processed_data.get("asset", "UNKNOWN"),
                        direction=processed_data.get("direction", "neutral"),
                        confidence_score=processed_data.get("confidence_score", 50),
                        risk_level=processed_data.get("risk_level", "medium"),
                        time_horizon=processed_data.get("time_horizon", "intraday"),
                    )
                    db.add(signal)
                    db.commit()
                    
                    logger.info(f"Created actionable signal for {signal.asset}: {signal.direction}")
                    
                    # Analyze signal further
                    analyze_signal_task.delay(signal.id)
                
            except Exception as e:
                logger.error(f"Error processing news item {news_item.id}: {str(e)}")
                # Mark as processed even if failed to avoid reprocessing
                news_item.processed = True
                db.add(news_item)
                db.commit()
                continue
                
    except Exception as e:
        logger.error(f"Error in process_news_task: {str(e)}")
    finally:
        db.close()

@celery_app.task(name="analyze_signal")
def analyze_signal_task(signal_id: int):
    """Enhanced signal analysis task with comprehensive technical analysis."""
    db: Session = database.SessionLocal()
    try:
        signal = db.query(models.Signal).filter(models.Signal.id == signal_id).first()
        if not signal:
            logger.error(f"Signal {signal_id} not found")
            return
        
        logger.info(f"Analyzing signal {signal_id} for {signal.asset}")
        
        # Perform comprehensive technical analysis
        analysis_result = analyze_signal(signal)
        
        if analysis_result:
            # Update signal with analysis results
            signal.entry_price = analysis_result.get("entry_price", 0)
            signal.stop_loss = analysis_result.get("stop_loss", 0)
            signal.take_profit = analysis_result.get("take_profit", 0)
            signal.position_size = analysis_result.get("position_size", 1.0)
            
            # Update confidence and risk based on technical analysis
            technical_confidence = analysis_result.get("confidence_score", signal.confidence_score)
            signal.confidence_score = min(100, max(signal.confidence_score, technical_confidence))
            signal.risk_level = analysis_result.get("risk_level", signal.risk_level)
            
            db.add(signal)
            db.commit()
            
            # Perform risk management analysis
            risk_manager = AdvancedRiskManager()
            
            # Prepare signal data for risk analysis
            signal_data = {
                "asset": signal.asset,
                "direction": signal.direction,
                "entry_price": signal.entry_price,
                "stop_loss": signal.stop_loss,
                "take_profit": signal.take_profit,
                "confidence_score": signal.confidence_score,
                "risk_level": signal.risk_level,
                "technical_indicators": analysis_result.get("technical_indicators", {}),
                "sector": "general"  # Could be extracted from news metadata
            }
            
            # Run comprehensive risk analysis
            try:
                trade_simulation = risk_manager.simulate_trade_outcomes(signal_data)
                
                # Create enhanced broadcast message
                broadcast_data = {
                    "type": "new_signal",
                    "signal": {
                        "id": signal.id,
                        "asset": signal.asset,
                        "direction": signal.direction,
                        "entry_price": signal.entry_price,
                        "stop_loss": signal.stop_loss,
                        "take_profit": signal.take_profit,
                        "confidence_score": signal.confidence_score,
                        "risk_level": signal.risk_level,
                        "time_horizon": signal.time_horizon,
                        "reasoning": analysis_result.get("reasoning", ""),
                        "analysis_summary": analysis_result.get("analysis_summary", ""),
                        "created_at": signal.created_at.isoformat() if signal.created_at else None
                    },
                    "risk_analysis": {
                        "recommendation": trade_simulation.get("recommendation", ""),
                        "expected_return": trade_simulation.get("monte_carlo_results", {}).get("simulation_results", {}).get("expected_return", 0),
                        "win_rate": trade_simulation.get("monte_carlo_results", {}).get("simulation_results", {}).get("win_rate", 0),
                        "risk_reward_ratio": trade_simulation.get("risk_reward_ratio", 0)
                    }
                }
                
                # Broadcast enhanced signal to WebSocket clients
                asyncio.run(broadcast_message(json.dumps(broadcast_data)))
                
                logger.info(f"Signal analysis completed for {signal.asset}: {analysis_result.get('direction', 'neutral')} with {signal.confidence_score}% confidence")
                
            except Exception as e:
                logger.error(f"Error in risk analysis for signal {signal_id}: {str(e)}")
                # Still broadcast basic signal even if risk analysis fails
                basic_broadcast = {
                    "type": "new_signal",
                    "signal": {
                        "id": signal.id,
                        "asset": signal.asset,
                        "direction": signal.direction,
                        "entry_price": signal.entry_price,
                        "confidence_score": signal.confidence_score,
                        "reasoning": analysis_result.get("reasoning", "Technical analysis completed")
                    }
                }
                asyncio.run(broadcast_message(json.dumps(basic_broadcast)))
        
        else:
            logger.warning(f"No analysis result for signal {signal_id}")
            
    except Exception as e:
        logger.error(f"Error in analyze_signal_task for signal {signal_id}: {str(e)}")
    finally:
        db.close()

@celery_app.task(name="cleanup_old_signals")
def cleanup_old_signals_task():
    """Clean up old processed signals to prevent database bloat."""
    db: Session = database.SessionLocal()
    try:
        from datetime import datetime, timedelta
        
        # Delete signals older than 30 days
        cutoff_date = datetime.utcnow() - timedelta(days=30)
        old_signals = db.query(models.Signal).filter(models.Signal.created_at < cutoff_date).all()
        
        for signal in old_signals:
            db.delete(signal)
        
        db.commit()
        logger.info(f"Cleaned up {len(old_signals)} old signals")
        
    except Exception as e:
        logger.error(f"Error in cleanup_old_signals_task: {str(e)}")
    finally:
        db.close()

@celery_app.task(name="update_signal_performance")
def update_signal_performance_task():
    """Update performance metrics for executed signals."""
    db: Session = database.SessionLocal()
    try:
        # Get signals that have been executed but not performance-tracked
        from datetime import datetime, timedelta
        
        recent_signals = db.query(models.Signal).filter(
            models.Signal.created_at > datetime.utcnow() - timedelta(days=7)
        ).all()
        
        # This would typically fetch current prices and calculate P&L
        # For now, we'll just log the task execution
        logger.info(f"Performance tracking task executed for {len(recent_signals)} recent signals")
        
    except Exception as e:
        logger.error(f"Error in update_signal_performance_task: {str(e)}")
    finally:
        db.close()
