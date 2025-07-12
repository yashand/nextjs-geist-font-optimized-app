import numpy as np
import pandas as pd
import logging
from typing import Dict, Any, List, Optional, Tuple
from scipy import stats
import warnings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Suppress warnings
warnings.filterwarnings("ignore", category=RuntimeWarning)

class AdvancedRiskManager:
    """Enhanced risk management system with portfolio analytics and Monte Carlo simulations."""
    
    def __init__(self, portfolio_value: float = 100000, max_portfolio_risk: float = 0.02):
        self.portfolio_value = portfolio_value
        self.max_portfolio_risk = max_portfolio_risk  # Maximum 2% portfolio risk per trade
        self.positions = {}  # Track current positions
        self.correlation_matrix = None
        self.sector_exposure = {}
        
    def calculate_position_size(self, signal_data: Dict[str, Any], portfolio_data: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Calculate optimal position size using multiple risk management techniques.
        """
        try:
            confidence_score = signal_data.get('confidence_score', 50)
            risk_level = signal_data.get('risk_level', 'medium')
            entry_price = signal_data.get('entry_price', 100)
            stop_loss = signal_data.get('stop_loss', entry_price * 0.95)
            
            # Risk per share
            risk_per_share = abs(entry_price - stop_loss)
            
            # Kelly Criterion calculation
            kelly_size = self._calculate_kelly_criterion(confidence_score, risk_per_share, entry_price)
            
            # Fixed fractional sizing
            fixed_fractional_size = self._calculate_fixed_fractional(risk_level)
            
            # Volatility-adjusted sizing
            volatility_adjusted_size = self._calculate_volatility_adjusted_size(signal_data)
            
            # Portfolio heat adjustment
            portfolio_heat_adjustment = self._calculate_portfolio_heat_adjustment(portfolio_data)
            
            # Combine sizing methods
            base_size = np.mean([kelly_size, fixed_fractional_size, volatility_adjusted_size])
            adjusted_size = base_size * portfolio_heat_adjustment
            
            # Apply maximum position limits
            max_position_value = self.portfolio_value * 0.1  # Max 10% per position
            max_shares = max_position_value / entry_price
            
            # Calculate final position size
            risk_based_shares = (self.portfolio_value * self.max_portfolio_risk) / risk_per_share
            final_shares = min(adjusted_size, max_shares, risk_based_shares)
            
            position_value = final_shares * entry_price
            portfolio_percentage = (position_value / self.portfolio_value) * 100
            
            return {
                "shares": max(1, int(final_shares)),
                "position_value": round(position_value, 2),
                "portfolio_percentage": round(portfolio_percentage, 2),
                "risk_per_share": round(risk_per_share, 2),
                "kelly_size": round(kelly_size, 2),
                "fixed_fractional_size": round(fixed_fractional_size, 2),
                "volatility_adjusted_size": round(volatility_adjusted_size, 2),
                "portfolio_heat_adjustment": round(portfolio_heat_adjustment, 3),
                "max_risk_amount": round(final_shares * risk_per_share, 2)
            }
            
        except Exception as e:
            logger.error(f"Error calculating position size: {str(e)}")
            return {
                "shares": 1,
                "position_value": entry_price,
                "portfolio_percentage": 1.0,
                "risk_per_share": entry_price * 0.05,
                "max_risk_amount": entry_price * 0.05,
                "error": str(e)
            }
    
    def _calculate_kelly_criterion(self, confidence_score: float, risk_per_share: float, entry_price: float) -> float:
        """Calculate Kelly Criterion position size."""
        try:
            # Convert confidence to win probability
            win_probability = confidence_score / 100
            
            # Assume average win is 2x the risk (2:1 reward-to-risk ratio)
            average_win = risk_per_share * 2
            average_loss = risk_per_share
            
            # Kelly formula: f = (bp - q) / b
            # where b = odds received (average_win/average_loss), p = win probability, q = loss probability
            b = average_win / average_loss
            p = win_probability
            q = 1 - win_probability
            
            kelly_fraction = (b * p - q) / b
            
            # Apply Kelly fraction to portfolio (with safety factor of 0.25)
            kelly_size = max(0, kelly_fraction * 0.25 * self.portfolio_value / entry_price)
            
            return kelly_size
            
        except Exception as e:
            logger.error(f"Error in Kelly calculation: {str(e)}")
            return self.portfolio_value * 0.01 / entry_price  # Default 1% risk
    
    def _calculate_fixed_fractional(self, risk_level: str) -> float:
        """Calculate fixed fractional position size based on risk level."""
        risk_multipliers = {
            'low': 0.03,     # 3% of portfolio
            'medium': 0.02,  # 2% of portfolio
            'high': 0.01     # 1% of portfolio
        }
        
        risk_fraction = risk_multipliers.get(risk_level, 0.02)
        return self.portfolio_value * risk_fraction / 100  # Convert to shares equivalent
    
    def _calculate_volatility_adjusted_size(self, signal_data: Dict[str, Any]) -> float:
        """Adjust position size based on asset volatility."""
        try:
            # Get ATR or volatility measure
            technical_indicators = signal_data.get('technical_indicators', {})
            atr = technical_indicators.get('atr', 0)
            entry_price = signal_data.get('entry_price', 100)
            
            if atr and entry_price:
                # Calculate volatility as percentage
                volatility_pct = (atr / entry_price) * 100
                
                # Inverse relationship: higher volatility = smaller position
                if volatility_pct > 5:  # High volatility
                    volatility_adjustment = 0.5
                elif volatility_pct > 3:  # Medium volatility
                    volatility_adjustment = 0.75
                else:  # Low volatility
                    volatility_adjustment = 1.0
                
                base_size = self.portfolio_value * 0.02 / entry_price
                return base_size * volatility_adjustment
            
            return self.portfolio_value * 0.02 / entry_price
            
        except Exception as e:
            logger.error(f"Error in volatility adjustment: {str(e)}")
            return self.portfolio_value * 0.02 / 100
    
    def _calculate_portfolio_heat_adjustment(self, portfolio_data: Optional[Dict]) -> float:
        """Adjust position size based on current portfolio heat (total risk exposure)."""
        try:
            if not portfolio_data:
                return 1.0
            
            # Calculate current portfolio heat
            current_risk = portfolio_data.get('total_risk_exposure', 0)
            max_portfolio_heat = self.portfolio_value * 0.06  # Max 6% total portfolio risk
            
            if current_risk >= max_portfolio_heat:
                return 0.1  # Severely reduce new positions
            elif current_risk >= max_portfolio_heat * 0.8:
                return 0.5  # Moderately reduce new positions
            else:
                return 1.0  # Normal position sizing
                
        except Exception as e:
            logger.error(f"Error in portfolio heat calculation: {str(e)}")
            return 1.0
    
    def monte_carlo_simulation(self, signal_data: Dict[str, Any], num_simulations: int = 5000, 
                             time_horizon: int = 20) -> Dict[str, Any]:
        """
        Run comprehensive Monte Carlo simulation for trade outcomes.
        """
        try:
            entry_price = signal_data.get('entry_price', 100)
            stop_loss = signal_data.get('stop_loss', entry_price * 0.95)
            take_profit = signal_data.get('take_profit', entry_price * 1.1)
            confidence_score = signal_data.get('confidence_score', 50)
            
            # Get volatility from technical indicators
            technical_indicators = signal_data.get('technical_indicators', {})
            atr = technical_indicators.get('atr', entry_price * 0.02)
            daily_volatility = atr / entry_price
            
            # Simulation parameters
            win_probability = confidence_score / 100
            
            outcomes = []
            price_paths = []
            
            for _ in range(num_simulations):
                # Generate price path using geometric Brownian motion
                price_path = self._generate_price_path(
                    entry_price, daily_volatility, time_horizon, win_probability
                )
                price_paths.append(price_path)
                
                # Determine outcome
                final_price = price_path[-1]
                
                if any(p <= stop_loss for p in price_path):
                    # Hit stop loss
                    outcome = (stop_loss - entry_price) / entry_price
                elif any(p >= take_profit for p in price_path):
                    # Hit take profit
                    outcome = (take_profit - entry_price) / entry_price
                else:
                    # Hold to end
                    outcome = (final_price - entry_price) / entry_price
                
                outcomes.append(outcome)
            
            outcomes = np.array(outcomes)
            
            # Calculate statistics
            win_rate = np.sum(outcomes > 0) / len(outcomes)
            avg_win = np.mean(outcomes[outcomes > 0]) if np.any(outcomes > 0) else 0
            avg_loss = np.mean(outcomes[outcomes < 0]) if np.any(outcomes < 0) else 0
            
            # Risk metrics
            var_95 = np.percentile(outcomes, 5)  # Value at Risk (95% confidence)
            cvar_95 = np.mean(outcomes[outcomes <= var_95])  # Conditional VaR
            
            # Outcome probabilities
            prob_profit = np.sum(outcomes > 0) / len(outcomes)
            prob_loss = np.sum(outcomes < 0) / len(outcomes)
            prob_breakeven = np.sum(np.abs(outcomes) < 0.001) / len(outcomes)
            
            # Expected value
            expected_return = np.mean(outcomes)
            
            return {
                "simulation_results": {
                    "expected_return": round(expected_return * 100, 2),
                    "win_rate": round(win_rate * 100, 2),
                    "average_win": round(avg_win * 100, 2),
                    "average_loss": round(avg_loss * 100, 2),
                    "profit_factor": round(abs(avg_win / avg_loss) if avg_loss != 0 else 0, 2),
                    "var_95": round(var_95 * 100, 2),
                    "cvar_95": round(cvar_95 * 100, 2),
                    "max_gain": round(np.max(outcomes) * 100, 2),
                    "max_loss": round(np.min(outcomes) * 100, 2),
                    "std_deviation": round(np.std(outcomes) * 100, 2)
                },
                "outcome_probabilities": {
                    "probability_profit": round(prob_profit * 100, 2),
                    "probability_loss": round(prob_loss * 100, 2),
                    "probability_breakeven": round(prob_breakeven * 100, 2)
                },
                "percentiles": {
                    "p10": round(np.percentile(outcomes, 10) * 100, 2),
                    "p25": round(np.percentile(outcomes, 25) * 100, 2),
                    "p50": round(np.percentile(outcomes, 50) * 100, 2),
                    "p75": round(np.percentile(outcomes, 75) * 100, 2),
                    "p90": round(np.percentile(outcomes, 90) * 100, 2)
                },
                "recommendation": self._generate_monte_carlo_recommendation(expected_return, var_95, win_rate)
            }
            
        except Exception as e:
            logger.error(f"Error in Monte Carlo simulation: {str(e)}")
            return {
                "simulation_results": {"error": str(e)},
                "outcome_probabilities": {},
                "percentiles": {},
                "recommendation": "Unable to perform simulation due to error"
            }
    
    def _generate_price_path(self, start_price: float, volatility: float, 
                           time_horizon: int, drift_bias: float) -> List[float]:
        """Generate a realistic price path using geometric Brownian motion."""
        
        # Adjust drift based on win probability
        drift = (drift_bias - 0.5) * 0.1  # Convert to daily drift
        
        prices = [start_price]
        
        for _ in range(time_horizon):
            # Random walk with drift
            random_shock = np.random.normal(0, 1)
            price_change = drift + volatility * random_shock
            new_price = prices[-1] * (1 + price_change)
            prices.append(max(new_price, 0.01))  # Prevent negative prices
        
        return prices
    
    def _generate_monte_carlo_recommendation(self, expected_return: float, 
                                          var_95: float, win_rate: float) -> str:
        """Generate trading recommendation based on Monte Carlo results."""
        
        if expected_return > 0.05 and var_95 > -0.1 and win_rate > 0.6:
            return "STRONG BUY - Favorable risk/reward profile with high win probability"
        elif expected_return > 0.02 and var_95 > -0.15 and win_rate > 0.5:
            return "BUY - Positive expected return with acceptable risk"
        elif expected_return > -0.02 and var_95 > -0.2:
            return "HOLD - Neutral expected return, monitor closely"
        elif expected_return < -0.05 or var_95 < -0.25:
            return "AVOID - Poor risk/reward profile, high downside risk"
        else:
            return "CAUTION - Mixed signals, consider reducing position size"
    
    def calculate_portfolio_correlation(self, assets: List[str], 
                                     returns_data: Optional[pd.DataFrame] = None) -> Dict[str, Any]:
        """Calculate correlation matrix and portfolio diversification metrics."""
        try:
            if returns_data is None or returns_data.empty:
                return {"error": "No returns data provided"}
            
            # Calculate correlation matrix
            correlation_matrix = returns_data.corr()
            
            # Calculate average correlation
            avg_correlation = correlation_matrix.values[np.triu_indices_from(correlation_matrix.values, k=1)].mean()
            
            # Diversification ratio
            portfolio_weights = np.ones(len(assets)) / len(assets)  # Equal weights
            portfolio_variance = np.dot(portfolio_weights, np.dot(returns_data.cov(), portfolio_weights))
            individual_variances = returns_data.var()
            weighted_avg_variance = np.dot(portfolio_weights, individual_variances)
            diversification_ratio = weighted_avg_variance / portfolio_variance if portfolio_variance > 0 else 1
            
            # Identify highly correlated pairs
            high_correlation_pairs = []
            for i in range(len(correlation_matrix.columns)):
                for j in range(i+1, len(correlation_matrix.columns)):
                    corr_value = correlation_matrix.iloc[i, j]
                    if abs(corr_value) > 0.7:
                        high_correlation_pairs.append({
                            "asset1": correlation_matrix.columns[i],
                            "asset2": correlation_matrix.columns[j],
                            "correlation": round(corr_value, 3)
                        })
            
            return {
                "correlation_matrix": correlation_matrix.round(3).to_dict(),
                "average_correlation": round(avg_correlation, 3),
                "diversification_ratio": round(diversification_ratio, 3),
                "high_correlation_pairs": high_correlation_pairs,
                "diversification_score": self._calculate_diversification_score(avg_correlation, len(assets))
            }
            
        except Exception as e:
            logger.error(f"Error calculating portfolio correlation: {str(e)}")
            return {"error": str(e)}
    
    def _calculate_diversification_score(self, avg_correlation: float, num_assets: int) -> str:
        """Calculate diversification score based on correlation and number of assets."""
        
        if num_assets < 3:
            return "POOR - Too few assets"
        elif avg_correlation > 0.8:
            return "POOR - High correlation between assets"
        elif avg_correlation > 0.6:
            return "FAIR - Moderate correlation, consider more diverse assets"
        elif avg_correlation > 0.4:
            return "GOOD - Well diversified portfolio"
        else:
            return "EXCELLENT - Highly diversified portfolio"
    
    def dynamic_stop_loss(self, entry_price: float, current_price: float, 
                         atr: float, direction: str = 'long', 
                         trailing_factor: float = 2.0) -> Dict[str, Any]:
        """
        Calculate dynamic trailing stop loss based on ATR and price movement.
        """
        try:
            if direction.lower() == 'long':
                # For long positions
                basic_stop = entry_price - (atr * trailing_factor)
                trailing_stop = current_price - (atr * trailing_factor)
                dynamic_stop = max(basic_stop, trailing_stop)
                
                # Don't let stop loss go above entry for long positions
                final_stop = min(dynamic_stop, entry_price * 0.95)
                
            else:  # short position
                # For short positions
                basic_stop = entry_price + (atr * trailing_factor)
                trailing_stop = current_price + (atr * trailing_factor)
                dynamic_stop = min(basic_stop, trailing_stop)
                
                # Don't let stop loss go below entry for short positions
                final_stop = max(dynamic_stop, entry_price * 1.05)
            
            stop_distance = abs(current_price - final_stop)
            stop_percentage = (stop_distance / current_price) * 100
            
            return {
                "stop_loss_price": round(final_stop, 2),
                "stop_distance": round(stop_distance, 2),
                "stop_percentage": round(stop_percentage, 2),
                "atr_multiplier": trailing_factor,
                "is_trailing": trailing_stop != basic_stop
            }
            
        except Exception as e:
            logger.error(f"Error calculating dynamic stop loss: {str(e)}")
            return {
                "stop_loss_price": entry_price * 0.95 if direction.lower() == 'long' else entry_price * 1.05,
                "error": str(e)
            }
    
    def check_drawdown(self, portfolio_values: List[float]) -> Dict[str, Any]:
        """
        Calculate comprehensive drawdown metrics.
        """
        try:
            if not portfolio_values or len(portfolio_values) < 2:
                return {"error": "Insufficient portfolio data"}
            
            portfolio_series = pd.Series(portfolio_values)
            
            # Calculate running maximum (peak)
            running_max = portfolio_series.expanding().max()
            
            # Calculate drawdown
            drawdown = (portfolio_series - running_max) / running_max
            
            # Maximum drawdown
            max_drawdown = drawdown.min()
            
            # Current drawdown
            current_drawdown = drawdown.iloc[-1]
            
            # Drawdown duration
            drawdown_periods = []
            in_drawdown = False
            start_period = 0
            
            for i, dd in enumerate(drawdown):
                if dd < 0 and not in_drawdown:
                    in_drawdown = True
                    start_period = i
                elif dd >= 0 and in_drawdown:
                    in_drawdown = False
                    drawdown_periods.append(i - start_period)
            
            # If still in drawdown
            if in_drawdown:
                drawdown_periods.append(len(drawdown) - start_period)
            
            avg_drawdown_duration = np.mean(drawdown_periods) if drawdown_periods else 0
            max_drawdown_duration = max(drawdown_periods) if drawdown_periods else 0
            
            # Recovery factor
            total_return = (portfolio_values[-1] - portfolio_values[0]) / portfolio_values[0]
            recovery_factor = abs(total_return / max_drawdown) if max_drawdown != 0 else 0
            
            return {
                "max_drawdown": round(max_drawdown * 100, 2),
                "current_drawdown": round(current_drawdown * 100, 2),
                "avg_drawdown_duration": round(avg_drawdown_duration, 1),
                "max_drawdown_duration": max_drawdown_duration,
                "recovery_factor": round(recovery_factor, 2),
                "total_return": round(total_return * 100, 2),
                "risk_assessment": self._assess_drawdown_risk(max_drawdown, current_drawdown)
            }
            
        except Exception as e:
            logger.error(f"Error calculating drawdown: {str(e)}")
            return {"error": str(e)}
    
    def _assess_drawdown_risk(self, max_drawdown: float, current_drawdown: float) -> str:
        """Assess risk level based on drawdown metrics."""
        
        if max_drawdown < -0.2:  # More than 20% drawdown
            return "HIGH RISK - Significant drawdown detected"
        elif max_drawdown < -0.1:  # More than 10% drawdown
            return "MEDIUM RISK - Moderate drawdown"
        elif current_drawdown < -0.05:  # Currently in 5%+ drawdown
            return "CAUTION - Currently in drawdown"
        else:
            return "LOW RISK - Acceptable drawdown levels"
    
    def simulate_trade_outcomes(self, signal_data: Dict[str, Any], 
                              portfolio_data: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Simulate comprehensive trade outcomes with portfolio impact analysis.
        """
        try:
            # Run Monte Carlo simulation
            mc_results = self.monte_carlo_simulation(signal_data)
            
            # Calculate position sizing
            position_sizing = self.calculate_position_size(signal_data, portfolio_data)
            
            # Simulate portfolio impact
            position_value = position_sizing.get('position_value', 0)
            max_risk = position_sizing.get('max_risk_amount', 0)
            
            # Portfolio impact scenarios
            scenarios = {
                "best_case": {
                    "return_pct": mc_results['percentiles']['p90'],
                    "portfolio_impact": (position_value * mc_results['percentiles']['p90'] / 100) / self.portfolio_value * 100
                },
                "expected_case": {
                    "return_pct": mc_results['simulation_results']['expected_return'],
                    "portfolio_impact": (position_value * mc_results['simulation_results']['expected_return'] / 100) / self.portfolio_value * 100
                },
                "worst_case": {
                    "return_pct": mc_results['percentiles']['p10'],
                    "portfolio_impact": (position_value * mc_results['percentiles']['p10'] / 100) / self.portfolio_value * 100
                },
                "stop_loss_case": {
                    "return_pct": -max_risk / position_value * 100 if position_value > 0 else 0,
                    "portfolio_impact": -max_risk / self.portfolio_value * 100
                }
            }
            
            # Risk-adjusted recommendation
            risk_reward_ratio = abs(scenarios['best_case']['return_pct'] / scenarios['worst_case']['return_pct']) if scenarios['worst_case']['return_pct'] != 0 else 0
            
            recommendation = self._generate_trade_recommendation(
                mc_results, position_sizing, risk_reward_ratio, scenarios
            )
            
            return {
                "monte_carlo_results": mc_results,
                "position_sizing": position_sizing,
                "scenarios": scenarios,
                "risk_reward_ratio": round(risk_reward_ratio, 2),
                "recommendation": recommendation,
                "hedging_suggestions": self._suggest_hedging_strategies(signal_data, scenarios)
            }
            
        except Exception as e:
            logger.error(f"Error in trade outcome simulation: {str(e)}")
            return {"error": str(e)}
    
    def _generate_trade_recommendation(self, mc_results: Dict, position_sizing: Dict, 
                                     risk_reward_ratio: float, scenarios: Dict) -> str:
        """Generate comprehensive trade recommendation."""
        
        expected_return = mc_results['simulation_results']['expected_return']
        win_rate = mc_results['simulation_results']['win_rate']
        max_portfolio_impact = abs(scenarios['worst_case']['portfolio_impact'])
        
        if (expected_return > 3 and win_rate > 60 and risk_reward_ratio > 2 and max_portfolio_impact < 2):
            return "STRONG BUY - Excellent risk/reward with minimal portfolio impact"
        elif (expected_return > 1 and win_rate > 50 and risk_reward_ratio > 1.5):
            return "BUY - Positive expected return with acceptable risk"
        elif (expected_return > -1 and max_portfolio_impact < 1):
            return "NEUTRAL - Consider smaller position or wait for better setup"
        else:
            return "AVOID - Poor risk/reward profile or excessive portfolio risk"
    
    def _suggest_hedging_strategies(self, signal_data: Dict, scenarios: Dict) -> List[str]:
        """Suggest hedging strategies based on risk analysis."""
        
        suggestions = []
        
        # High portfolio impact
        if abs(scenarios['worst_case']['portfolio_impact']) > 2:
            suggestions.append("Consider reducing position size due to high portfolio impact")
        
        # High volatility
        technical_indicators = signal_data.get('technical_indicators', {})
        if technical_indicators.get('atr', 0) / signal_data.get('entry_price', 100) > 0.05:
            suggestions.append("High volatility detected - consider protective options strategies")
        
        # Sector concentration
        sector = signal_data.get('sector', 'unknown')
        if sector != 'unknown':
            suggestions.append(f"Monitor {sector} sector exposure for concentration risk")
        
        # Market correlation
        suggestions.append("Consider market hedging if position represents significant portfolio exposure")
        
        return suggestions

# Legacy class for backward compatibility
class RiskManager(AdvancedRiskManager):
    """Legacy risk manager class - redirects to AdvancedRiskManager."""
    
    def __init__(self, portfolio_value=100000):
        super().__init__(portfolio_value=portfolio_value)
        logger.warning("RiskManager class is deprecated. Use AdvancedRiskManager instead.")
