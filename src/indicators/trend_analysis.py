"""
Trend analysis and identification module.
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class TrendDirection(Enum):
    UPTREND = "uptrend"
    DOWNTREND = "downtrend"
    SIDEWAYS = "sideways"


class TrendStrength(Enum):
    WEAK = "weak"
    MODERATE = "moderate"
    STRONG = "strong"


@dataclass
class TrendMove:
    """Represents a trend movement."""
    start_idx: int
    end_idx: int
    start_price: float
    end_price: float
    direction: TrendDirection
    strength: TrendStrength
    slope: float
    r_squared: float  # Correlation coefficient
    
    @property
    def duration(self) -> int:
        return self.end_idx - self.start_idx
    
    @property
    def price_change(self) -> float:
        return self.end_price - self.start_price
    
    @property
    def percentage_change(self) -> float:
        return (self.price_change / self.start_price) * 100


class TrendAnalyzer:
    """Analyzes price trends and movements."""
    
    def __init__(self, min_trend_length: int = 10):
        self.min_trend_length = min_trend_length
    
    def identify_trends(self, data: pd.DataFrame, window: int = 20) -> List[TrendMove]:
        """Identify trend movements using moving averages and linear regression."""
        trends = []
        
        # Calculate moving averages
        data['ma_short'] = data['close'].rolling(window=window//2).mean()
        data['ma_long'] = data['close'].rolling(window=window).mean()
        
        # Find trend changes
        trend_changes = self._find_trend_changes(data)
        
        # Create trend moves between changes
        for i in range(len(trend_changes) - 1):
            start_idx = trend_changes[i]
            end_idx = trend_changes[i + 1]
            
            if end_idx - start_idx >= self.min_trend_length:
                trend_move = self._analyze_trend_segment(data, start_idx, end_idx)
                if trend_move:
                    trends.append(trend_move)
        
        return trends
    
    def _find_trend_changes(self, data: pd.DataFrame) -> List[int]:
        """Find points where trend direction changes."""
        changes = [0]  # Start with first index
        
        # Compare short MA vs long MA to determine trend
        for i in range(1, len(data) - 1):
            if pd.isna(data['ma_short'].iloc[i]) or pd.isna(data['ma_long'].iloc[i]):
                continue
            
            current_trend = self._get_trend_direction_at_point(data, i)
            previous_trend = self._get_trend_direction_at_point(data, i - 1)
            
            if current_trend != previous_trend:
                changes.append(i)
        
        changes.append(len(data) - 1)  # End with last index
        return changes
    
    def _get_trend_direction_at_point(self, data: pd.DataFrame, idx: int) -> TrendDirection:
        """Determine trend direction at specific point."""
        if pd.isna(data['ma_short'].iloc[idx]) or pd.isna(data['ma_long'].iloc[idx]):
            return TrendDirection.SIDEWAYS
        
        ma_short = data['ma_short'].iloc[idx]
        ma_long = data['ma_long'].iloc[idx]
        
        if ma_short > ma_long * 1.001:  # Small threshold to avoid noise
            return TrendDirection.UPTREND
        elif ma_short < ma_long * 0.999:
            return TrendDirection.DOWNTREND
        else:
            return TrendDirection.SIDEWAYS
    
    def _analyze_trend_segment(self, data: pd.DataFrame, start_idx: int, end_idx: int) -> Optional[TrendMove]:
        """Analyze a specific trend segment using linear regression."""
        segment = data.iloc[start_idx:end_idx + 1]
        
        if len(segment) < self.min_trend_length:
            return None
        
        # Linear regression
        x = np.arange(len(segment))
        y = segment['close'].values
        
        # Remove NaN values
        valid_mask = ~np.isnan(y)
        if np.sum(valid_mask) < self.min_trend_length:
            return None
        
        x_valid = x[valid_mask]
        y_valid = y[valid_mask]
        
        # Calculate slope and R-squared
        slope, intercept = np.polyfit(x_valid, y_valid, 1)
        y_pred = slope * x_valid + intercept
        
        ss_res = np.sum((y_valid - y_pred) ** 2)
        ss_tot = np.sum((y_valid - np.mean(y_valid)) ** 2)
        r_squared = 1 - (ss_res / ss_tot) if ss_tot != 0 else 0
        
        # Determine trend direction and strength
        direction = self._classify_trend_direction(slope, r_squared)
        strength = self._classify_trend_strength(abs(slope), r_squared)
        
        return TrendMove(
            start_idx=start_idx,
            end_idx=end_idx,
            start_price=segment['close'].iloc[0],
            end_price=segment['close'].iloc[-1],
            direction=direction,
            strength=strength,
            slope=slope,
            r_squared=r_squared
        )
    
    def _classify_trend_direction(self, slope: float, r_squared: float) -> TrendDirection:
        """Classify trend direction based on slope."""
        if r_squared < 0.3:  # Low correlation = sideways
            return TrendDirection.SIDEWAYS
        
        if slope > 0.0001:
            return TrendDirection.UPTREND
        elif slope < -0.0001:
            return TrendDirection.DOWNTREND
        else:
            return TrendDirection.SIDEWAYS
    
    def _classify_trend_strength(self, abs_slope: float, r_squared: float) -> TrendStrength:
        """Classify trend strength based on slope magnitude and correlation."""
        strength_score = abs_slope * r_squared
        
        if strength_score > 0.001:
            return TrendStrength.STRONG
        elif strength_score > 0.0005:
            return TrendStrength.MODERATE
        else:
            return TrendStrength.WEAK
    
    def find_trend_continuations(self, trends: List[TrendMove]) -> List[Dict]:
        """Find trend continuation patterns."""
        continuations = []
        
        for i in range(len(trends) - 1):
            current_trend = trends[i]
            next_trend = trends[i + 1]
            
            # Check for continuation after brief correction
            if (current_trend.direction == next_trend.direction and
                current_trend.strength in [TrendStrength.MODERATE, TrendStrength.STRONG] and
                next_trend.strength in [TrendStrength.MODERATE, TrendStrength.STRONG]):
                
                continuations.append({
                    'type': 'continuation',
                    'direction': current_trend.direction.value,
                    'start_idx': current_trend.start_idx,
                    'end_idx': next_trend.end_idx,
                    'strength': 'strong' if current_trend.strength == TrendStrength.STRONG else 'moderate'
                })
        
        return continuations
    
    def find_trend_reversals(self, trends: List[TrendMove]) -> List[Dict]:
        """Find trend reversal patterns."""
        reversals = []
        
        for i in range(len(trends) - 1):
            current_trend = trends[i]
            next_trend = trends[i + 1]
            
            # Check for strong trend reversal
            if (current_trend.direction != next_trend.direction and
                current_trend.direction != TrendDirection.SIDEWAYS and
                next_trend.direction != TrendDirection.SIDEWAYS and
                current_trend.strength in [TrendStrength.MODERATE, TrendStrength.STRONG] and
                next_trend.strength in [TrendStrength.MODERATE, TrendStrength.STRONG]):
                
                reversals.append({
                    'type': 'reversal',
                    'from_direction': current_trend.direction.value,
                    'to_direction': next_trend.direction.value,
                    'reversal_point': current_trend.end_idx,
                    'strength': 'strong'
                })
        
        return reversals