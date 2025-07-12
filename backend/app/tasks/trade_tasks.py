from app.tasks import celery_app
from app.db import database, models
from sqlalchemy.orm import Session
from app.execution.broker import execute_trade_order, broker_interface
from app.processing.risk_management import AdvancedRiskManager
from app.api.v1.endpoints.websocket import broadcast_message
import asyncio
import logging
import json
from datetime import datetime, timezone

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@celery_app.task(name="execute_trade")
def execute_trade_task(signal_id: int):
    """Enhanced trade execution task with comprehensive risk management."""
    db: Session = database.SessionLocal()
    try:
        signal = db.query(models.Signal).filter(models.Signal.id == signal_id).first()
        if not signal:
            logger.error(f"Signal {signal_id} not found for trade execution")
            return
        
        logger.info(f"Executing trade for signal {signal_id}: {signal.asset} {signal.direction}")
        
        # Initialize risk manager
        risk_manager = AdvancedRiskManager()
        
        # Prepare signal data for position sizing
        signal_data = {
            "asset": signal.asset,
            "direction": signal.direction,
            "entry_price": signal.entry_price,
            "stop_loss": signal.stop_loss,
            "take_profit": signal.take_profit,
            "confidence_score": signal.confidence_score,
            "risk_level": signal.risk_level,
            "technical_indicators": {}  # Could be stored in signal metadata
        }
        
        # Calculate optimal position sizing
        position_sizing = risk_manager.calculate_position_size(signal_data)
        
        # Execute trade with enhanced broker interface
        execution_result = execute_trade_order(signal, position_sizing)
        
        # Create comprehensive trade record
        trade = models.Trade(
            signal_id=signal.id,
            executed_price=execution_result.get("executed_price", execution_result.get("price", 0)),
            quantity=execution_result.get("quantity", position_sizing.get("shares", 100)),
            status=execution_result.get("status", "unknown"),
        )
        
        db.add(trade)
        db.commit()
        
        # Log execution details
        if execution_result.get("status") == "executed":
            logger.info(f"Trade executed successfully: {execution_result.get('order_id')} - "
                       f"{signal.asset} {signal.direction} {trade.quantity} @ {trade.executed_price}")
            
            # Broadcast trade execution to WebSocket clients
            broadcast_data = {
                "type": "trade_executed",
                "trade": {
                    "id": trade.id,
                    "signal_id": signal.id,
                    "asset": signal.asset,
                    "direction": signal.direction,
                    "quantity": trade.quantity,
                    "executed_price": trade.executed_price,
                    "total_value": execution_result.get("total_value", 0),
                    "status": trade.status,
                    "executed_at": trade.executed_at.isoformat() if trade.executed_at else None,
                    "order_id": execution_result.get("order_id", ""),
                    "slippage": execution_result.get("slippage", 0),
                    "commission": execution_result.get("commission", {}).get("commission_amount", 0)
                },
                "execution_details": {
                    "execution_quality": execution_result.get("execution_quality", ""),
                    "market_impact": execution_result.get("market_impact", {}),
                    "bracket_orders": execution_result.get("bracket_orders", {})
                }
            }
            
            asyncio.run(broadcast_message(json.dumps(broadcast_data)))
            
        else:
            logger.error(f"Trade execution failed for signal {signal_id}: {execution_result.get('error', 'Unknown error')}")
            
            # Broadcast execution failure
            failure_data = {
                "type": "trade_failed",
                "signal_id": signal.id,
                "asset": signal.asset,
                "error": execution_result.get("error", "Trade execution failed"),
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            asyncio.run(broadcast_message(json.dumps(failure_data)))
        
    except Exception as e:
        logger.error(f"Error in execute_trade_task for signal {signal_id}: {str(e)}")
        
        # Create failed trade record
        try:
            trade = models.Trade(
                signal_id=signal_id,
                executed_price=0,
                quantity=0,
                status="error",
            )
            db.add(trade)
            db.commit()
        except Exception as db_error:
            logger.error(f"Failed to create error trade record: {str(db_error)}")
            
    finally:
        db.close()
