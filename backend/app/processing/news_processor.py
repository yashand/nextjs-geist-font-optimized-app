from transformers import pipeline
from textblob import TextBlob
import httpx
import json
import os
import logging
import re
from typing import Dict, Any, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize sentiment analysis pipeline (can be replaced with FinBERT or custom model)
sentiment_analyzer = pipeline("sentiment-analysis")

# Market-moving keywords categorized by impact level
HIGH_IMPACT_KEYWORDS = [
    'merger', 'acquisition', 'takeover', 'buyout', 'ipo', 'bankruptcy', 'fraud',
    'lawsuit', 'regulation', 'fed', 'interest rate', 'earnings surprise', 'guidance',
    'breakthrough', 'partnership', 'contract', 'approval', 'recall', 'investigation'
]

MEDIUM_IMPACT_KEYWORDS = [
    'earnings', 'revenue', 'profit', 'loss', 'dividend', 'split', 'upgrade',
    'downgrade', 'analyst', 'target price', 'recommendation', 'outlook'
]

SECTOR_KEYWORDS = {
    'tech': ['technology', 'software', 'ai', 'artificial intelligence', 'cloud', 'semiconductor'],
    'finance': ['bank', 'financial', 'credit', 'loan', 'mortgage', 'insurance'],
    'healthcare': ['pharma', 'drug', 'medical', 'healthcare', 'biotech', 'clinical'],
    'energy': ['oil', 'gas', 'renewable', 'solar', 'wind', 'energy'],
    'retail': ['retail', 'consumer', 'sales', 'store', 'e-commerce']
}

async def llm_summarize_news(news_text: str) -> Optional[Dict[str, Any]]:
    """
    Use LLM to analyze and summarize financial news for trading signals.
    """
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        logger.warning("OPENROUTER_API_KEY not found, skipping LLM analysis")
        return None
    
    try:
        system_prompt = """You are a professional financial analyst specializing in extracting trading signals from news. 
        Analyze the provided news and return a JSON response with the following structure:
        {
            "analysis_summary": "Brief summary of key points",
            "extracted_entities": ["list", "of", "companies", "or", "tickers"],
            "event_type": "merger|earnings|regulation|lawsuit|breakthrough|other",
            "market_impact": "high|medium|low",
            "sentiment": "positive|negative|neutral",
            "actionable": true/false,
            "reasoning": "Why this news is or isn't actionable for trading"
        }"""
        
        payload = {
            "model": "openai/gpt-4o",
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user", 
                    "content": [
                        {
                            "type": "text", 
                            "text": f"Analyze this financial news for trading signals: {news_text[:2000]}"
                        }
                    ]
                }
            ],
            "temperature": 0.3,
            "max_tokens": 500
        }
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                json=payload,
                headers=headers
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"]
                
                # Try to parse JSON from the response
                try:
                    # Extract JSON from the response if it's wrapped in markdown
                    json_match = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
                    if json_match:
                        content = json_match.group(1)
                    
                    return json.loads(content)
                except json.JSONDecodeError:
                    logger.error(f"Failed to parse LLM JSON response: {content}")
                    return None
            else:
                logger.error(f"LLM API error: {response.status_code} - {response.text}")
                return None
                
    except Exception as e:
        logger.error(f"Error in LLM analysis: {str(e)}")
        return None

def extract_tickers(text: str) -> list:
    """Extract potential stock tickers from text."""
    # Look for uppercase words 1-5 characters long
    potential_tickers = re.findall(r'\b[A-Z]{1,5}\b', text)
    
    # Filter out common words that aren't tickers
    common_words = {'THE', 'AND', 'FOR', 'ARE', 'BUT', 'NOT', 'YOU', 'ALL', 'CAN', 'HER', 'WAS', 'ONE', 'OUR', 'HAD', 'BY', 'UP', 'DO', 'NO', 'IF', 'TO', 'MY', 'IS', 'AT', 'AS', 'WE', 'ON', 'BE', 'OR', 'AN', 'WILL', 'SO', 'IT', 'OF', 'IN', 'HE', 'HAS', 'HIS', 'SHE', 'US', 'CEO', 'CFO', 'CTO', 'USA', 'UK', 'EU', 'AI', 'IT', 'TV', 'PC', 'PR', 'HR', 'IP', 'API', 'CEO', 'IPO', 'SEC', 'FDA', 'FTC', 'DOJ', 'FBI', 'CIA', 'NSA', 'IRS', 'GDP', 'CPI', 'PPI', 'PMI', 'Q1', 'Q2', 'Q3', 'Q4', 'YOY', 'QOQ', 'MOM', 'WOW', 'EOD', 'AH', 'PM', 'AM'}
    
    return [ticker for ticker in potential_tickers if ticker not in common_words]

def determine_sector(text: str) -> str:
    """Determine the sector based on keywords in the text."""
    text_lower = text.lower()
    
    for sector, keywords in SECTOR_KEYWORDS.items():
        if any(keyword in text_lower for keyword in keywords):
            return sector
    
    return 'general'

def calculate_impact_score(text: str, sentiment_score: float) -> float:
    """Calculate impact score based on keywords and sentiment."""
    text_lower = text.lower()
    
    high_impact_count = sum(1 for keyword in HIGH_IMPACT_KEYWORDS if keyword in text_lower)
    medium_impact_count = sum(1 for keyword in MEDIUM_IMPACT_KEYWORDS if keyword in text_lower)
    
    # Base impact from keywords
    keyword_impact = (high_impact_count * 0.3) + (medium_impact_count * 0.15)
    
    # Sentiment magnitude contribution
    sentiment_impact = abs(sentiment_score) * 0.4
    
    # Combine and normalize
    total_impact = min(1.0, keyword_impact + sentiment_impact + 0.1)
    
    return total_impact

async def process_news_item(news_item):
    """
    Process a news item to extract sentiment, impact, and actionable signals.
    Enhanced with LLM integration and advanced analysis.
    """
    text = news_item.headline + " " + (news_item.content or "")
    
    # Traditional sentiment analysis
    sentiment_result = sentiment_analyzer(text[:512])[0]
    sentiment_score = sentiment_result['score'] if sentiment_result['label'] == 'POSITIVE' else -sentiment_result['score']
    
    # LLM-enhanced analysis
    llm_analysis = await llm_summarize_news(text)
    
    # Extract tickers and entities
    extracted_tickers = extract_tickers(text)
    
    # Determine sector
    sector = determine_sector(text)
    
    # Calculate enhanced impact rating
    impact_rating = calculate_impact_score(text, sentiment_score)
    
    # Enhanced actionability determination
    high_impact_present = any(keyword in text.lower() for keyword in HIGH_IMPACT_KEYWORDS)
    medium_impact_present = any(keyword in text.lower() for keyword in MEDIUM_IMPACT_KEYWORDS)
    
    # Base actionability on multiple factors
    actionable = (
        (high_impact_present and abs(sentiment_score) > 0.5) or
        (medium_impact_present and abs(sentiment_score) > 0.7) or
        (llm_analysis and llm_analysis.get('actionable', False))
    )
    
    # Determine primary asset
    asset = "UNKNOWN"
    if extracted_tickers:
        asset = extracted_tickers[0]  # Take the first ticker found
    elif llm_analysis and llm_analysis.get('extracted_entities'):
        entities = llm_analysis['extracted_entities']
        if entities:
            asset = entities[0]
    
    # Enhanced direction logic
    direction = 'long' if sentiment_score > 0 else 'short'
    if llm_analysis and llm_analysis.get('sentiment'):
        llm_sentiment = llm_analysis['sentiment']
        if llm_sentiment == 'positive':
            direction = 'long'
        elif llm_sentiment == 'negative':
            direction = 'short'
        else:
            direction = 'neutral'
    
    # Enhanced confidence score
    base_confidence = min(100, abs(sentiment_score) * 100)
    if llm_analysis:
        # Boost confidence if LLM confirms actionability
        if llm_analysis.get('actionable', False):
            base_confidence = min(100, base_confidence * 1.2)
        
        # Adjust based on market impact
        impact_level = llm_analysis.get('market_impact', 'medium')
        if impact_level == 'high':
            base_confidence = min(100, base_confidence * 1.3)
        elif impact_level == 'low':
            base_confidence = max(20, base_confidence * 0.8)
    
    confidence_score = int(base_confidence)
    
    # Enhanced risk level determination
    risk_level = 'medium'
    if impact_rating > 0.8 or (llm_analysis and llm_analysis.get('market_impact') == 'high'):
        risk_level = 'high'
    elif impact_rating < 0.3 or (llm_analysis and llm_analysis.get('market_impact') == 'low'):
        risk_level = 'low'
    
    # Enhanced time horizon
    time_horizon = 'intraday'
    if llm_analysis:
        event_type = llm_analysis.get('event_type', 'other')
        if event_type in ['merger', 'acquisition', 'regulation']:
            time_horizon = '1_month'
        elif event_type in ['earnings', 'guidance']:
            time_horizon = '1_week'
        elif event_type in ['breakthrough', 'partnership']:
            time_horizon = '2_days'
    
    # Compile result
    result = {
        "sentiment_score": sentiment_score,
        "impact_rating": impact_rating,
        "actionable": actionable,
        "asset": asset,
        "direction": direction,
        "confidence_score": confidence_score,
        "risk_level": risk_level,
        "time_horizon": time_horizon,
        "sector": sector,
        "extracted_tickers": extracted_tickers,
    }
    
    # Add LLM analysis if available
    if llm_analysis:
        result.update({
            "analysis_summary": llm_analysis.get('analysis_summary', ''),
            "extracted_entities": llm_analysis.get('extracted_entities', []),
            "event_type": llm_analysis.get('event_type', 'other'),
            "market_impact": llm_analysis.get('market_impact', 'medium'),
            "reasoning": llm_analysis.get('reasoning', ''),
        })
    
    return result
