"""
Chart pattern recognition module.
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class PatternType(Enum):
    HEAD_AND_SHOULDERS = "head_and_shoulders"
    INVERSE_HEAD_AND_SHOULDERS = "inverse_head_and_shoulders"
    DOUBLE_TOP = "double_top"
    DOUBLE_BOTTOM = "double_bottom"
    TRIANGLE_ASCENDING = "triangle_ascending"
    TRIANGLE_DESCENDING = "triangle_descending"
    TRIANGLE_SYMMETRICAL = "triangle_symmetrical"
    WEDGE_RISING = "wedge_rising"
    WEDGE_FALLING = "wedge_falling"
    FLAG_BULL = "flag_bull"
    FLAG_BEAR = "flag_bear"
    PENNANT = "pennant"


@dataclass
class ChartPattern:
    """Represents a chart pattern."""
    pattern_type: PatternType
    start_idx: int
    end_idx: int
    key_points: List[Tuple[int, float]]  # (index, price) pairs
    confidence: float  # 0.0 to 1.0
    target_price: Optional[float] = None
    stop_loss: Optional[float] = None
    
    @property
    def duration(self) -> int:
        return self.end_idx - self.start_idx


class ChartPatternRecognizer:
    """Recognizes various chart patterns in price data."""
    
    def __init__(self, min_pattern_length: int = 20):
        self.min_pattern_length = min_pattern_length
        self.tolerance = 0.02  # 2% tolerance for pattern matching
    
    def find_all_patterns(self, data: pd.DataFrame) -> List[ChartPattern]:
        """Find all chart patterns in the data."""
        patterns = []
        
        # Find pivot points first
        pivots = self._find_pivot_points(data)
        
        # Look for different pattern types
        patterns.extend(self._find_head_and_shoulders(data, pivots))
        patterns.extend(self._find_double_tops_bottoms(data, pivots))
        patterns.extend(self._find_triangles(data, pivots))
        patterns.extend(self._find_wedges(data, pivots))
        patterns.extend(self._find_flags_pennants(data, pivots))
        
        return patterns
    
    def _find_pivot_points(self, data: pd.DataFrame, window: int = 5) -> List[Tuple[int, float, str]]:
        """Find swing highs and lows."""
        pivots = []
        
        for i in range(window, len(data) - window):
            # Check for swing high
            if all(data['high'].iloc[i] >= data['high'].iloc[i-j] for j in range(1, window+1)) and \
               all(data['high'].iloc[i] >= data['high'].iloc[i+j] for j in range(1, window+1)):
                pivots.append((i, data['high'].iloc[i], 'high'))
            
            # Check for swing low
            elif all(data['low'].iloc[i] <= data['low'].iloc[i-j] for j in range(1, window+1)) and \
                 all(data['low'].iloc[i] <= data['low'].iloc[i+j] for j in range(1, window+1)):
                pivots.append((i, data['low'].iloc[i], 'low'))
        
        return pivots
    
    def _find_head_and_shoulders(self, data: pd.DataFrame, pivots: List[Tuple[int, float, str]]) -> List[ChartPattern]:
        """Find head and shoulders patterns."""
        patterns = []
        highs = [p for p in pivots if p[2] == 'high']
        
        # Need at least 3 highs for H&S
        for i in range(len(highs) - 2):
            left_shoulder = highs[i]
            head = highs[i + 1]
            right_shoulder = highs[i + 2]
            
            # Check H&S criteria
            if (head[1] > left_shoulder[1] * (1 + self.tolerance) and
                head[1] > right_shoulder[1] * (1 + self.tolerance) and
                abs(left_shoulder[1] - right_shoulder[1]) / left_shoulder[1] < self.tolerance):
                
                # Find neckline (lows between shoulders and head)
                neckline_lows = [p for p in pivots if p[2] == 'low' and 
                               left_shoulder[0] < p[0] < right_shoulder[0]]
                
                if len(neckline_lows) >= 2:
                    neckline_price = np.mean([p[1] for p in neckline_lows])
                    
                    pattern = ChartPattern(
                        pattern_type=PatternType.HEAD_AND_SHOULDERS,
                        start_idx=left_shoulder[0],
                        end_idx=right_shoulder[0],
                        key_points=[left_shoulder, head, right_shoulder] + neckline_lows,
                        confidence=self._calculate_hs_confidence(left_shoulder, head, right_shoulder),
                        target_price=neckline_price - (head[1] - neckline_price),
                        stop_loss=head[1]
                    )
                    patterns.append(pattern)
        
        return patterns
    
    def _find_double_tops_bottoms(self, data: pd.DataFrame, pivots: List[Tuple[int, float, str]]) -> List[ChartPattern]:
        """Find double top and double bottom patterns."""
        patterns = []
        
        # Double tops
        highs = [p for p in pivots if p[2] == 'high']
        for i in range(len(highs) - 1):
            first_top = highs[i]
            second_top = highs[i + 1]
            
            # Check if tops are approximately equal
            if abs(first_top[1] - second_top[1]) / first_top[1] < self.tolerance:
                # Find valley between tops
                valley_lows = [p for p in pivots if p[2] == 'low' and 
                             first_top[0] < p[0] < second_top[0]]
                
                if valley_lows:
                    valley = min(valley_lows, key=lambda x: x[1])
                    
                    pattern = ChartPattern(
                        pattern_type=PatternType.DOUBLE_TOP,
                        start_idx=first_top[0],
                        end_idx=second_top[0],
                        key_points=[first_top, valley, second_top],
                        confidence=self._calculate_double_pattern_confidence(first_top, second_top),
                        target_price=valley[1] - (first_top[1] - valley[1]),
                        stop_loss=max(first_top[1], second_top[1])
                    )
                    patterns.append(pattern)
        
        # Double bottoms
        lows = [p for p in pivots if p[2] == 'low']
        for i in range(len(lows) - 1):
            first_bottom = lows[i]
            second_bottom = lows[i + 1]
            
            if abs(first_bottom[1] - second_bottom[1]) / first_bottom[1] < self.tolerance:
                # Find peak between bottoms
                peak_highs = [p for p in pivots if p[2] == 'high' and 
                            first_bottom[0] < p[0] < second_bottom[0]]
                
                if peak_highs:
                    peak = max(peak_highs, key=lambda x: x[1])
                    
                    pattern = ChartPattern(
                        pattern_type=PatternType.DOUBLE_BOTTOM,
                        start_idx=first_bottom[0],
                        end_idx=second_bottom[0],
                        key_points=[first_bottom, peak, second_bottom],
                        confidence=self._calculate_double_pattern_confidence(first_bottom, second_bottom),
                        target_price=peak[1] + (peak[1] - first_bottom[1]),
                        stop_loss=min(first_bottom[1], second_bottom[1])
                    )
                    patterns.append(pattern)
        
        return patterns
    
    def _find_triangles(self, data: pd.DataFrame, pivots: List[Tuple[int, float, str]]) -> List[ChartPattern]:
        """Find triangle patterns (ascending, descending, symmetrical)."""
        patterns = []
        
        # Need at least 4 pivots for triangle
        if len(pivots) < 4:
            return patterns
        
        # Look for triangle patterns in sliding windows
        for i in range(len(pivots) - 3):
            pattern_pivots = pivots[i:i+4]
            
            # Separate highs and lows
            highs = [p for p in pattern_pivots if p[2] == 'high']
            lows = [p for p in pattern_pivots if p[2] == 'low']
            
            if len(highs) >= 2 and len(lows) >= 2:
                # Calculate trendlines
                high_slope = self._calculate_trendline_slope(highs)
                low_slope = self._calculate_trendline_slope(lows)
                
                # Classify triangle type
                triangle_type = self._classify_triangle(high_slope, low_slope)
                
                if triangle_type:
                    pattern = ChartPattern(
                        pattern_type=triangle_type,
                        start_idx=pattern_pivots[0][0],
                        end_idx=pattern_pivots[-1][0],
                        key_points=pattern_pivots,
                        confidence=self._calculate_triangle_confidence(highs, lows),
                        target_price=self._calculate_triangle_target(data, pattern_pivots, triangle_type)
                    )
                    patterns.append(pattern)
        
        return patterns
    
    def _find_wedges(self, data: pd.DataFrame, pivots: List[Tuple[int, float, str]]) -> List[ChartPattern]:
        """Find rising and falling wedge patterns."""
        patterns = []
        
        for i in range(len(pivots) - 3):
            pattern_pivots = pivots[i:i+4]
            highs = [p for p in pattern_pivots if p[2] == 'high']
            lows = [p for p in pattern_pivots if p[2] == 'low']
            
            if len(highs) >= 2 and len(lows) >= 2:
                high_slope = self._calculate_trendline_slope(highs)
                low_slope = self._calculate_trendline_slope(lows)
                
                # Rising wedge: both slopes positive, converging
                if high_slope > 0 and low_slope > 0 and high_slope < low_slope:
                    pattern = ChartPattern(
                        pattern_type=PatternType.WEDGE_RISING,
                        start_idx=pattern_pivots[0][0],
                        end_idx=pattern_pivots[-1][0],
                        key_points=pattern_pivots,
                        confidence=0.7
                    )
                    patterns.append(pattern)
                
                # Falling wedge: both slopes negative, converging
                elif high_slope < 0 and low_slope < 0 and high_slope > low_slope:
                    pattern = ChartPattern(
                        pattern_type=PatternType.WEDGE_FALLING,
                        start_idx=pattern_pivots[0][0],
                        end_idx=pattern_pivots[-1][0],
                        key_points=pattern_pivots,
                        confidence=0.7
                    )
                    patterns.append(pattern)
        
        return patterns
    
    def _find_flags_pennants(self, data: pd.DataFrame, pivots: List[Tuple[int, float, str]]) -> List[ChartPattern]:
        """Find flag and pennant patterns."""
        patterns = []
        
        # Flags and pennants typically follow strong moves
        # Look for consolidation after strong price movement
        
        for i in range(20, len(data) - 20):  # Need room before and after
            # Check for strong move before consolidation
            lookback_start = max(0, i - 20)
            strong_move = abs(data['close'].iloc[i] - data['close'].iloc[lookback_start])
            avg_range = data['close'].iloc[lookback_start:i].std()
            
            if strong_move > avg_range * 2:  # Strong move detected
                # Look for consolidation pattern after
                consolidation_end = min(len(data), i + 15)
                consolidation_data = data.iloc[i:consolidation_end]
                
                if len(consolidation_data) > 5:
                    # Check if price is consolidating (low volatility)
                    consolidation_range = consolidation_data['high'].max() - consolidation_data['low'].min()
                    
                    if consolidation_range < strong_move * 0.3:  # Consolidation is small relative to move
                        # Determine if bull or bear flag
                        move_direction = 'up' if data['close'].iloc[i] > data['close'].iloc[lookback_start] else 'down'
                        
                        pattern_type = PatternType.FLAG_BULL if move_direction == 'up' else PatternType.FLAG_BEAR
                        
                        pattern = ChartPattern(
                            pattern_type=pattern_type,
                            start_idx=i,
                            end_idx=consolidation_end - 1,
                            key_points=[(i, data['close'].iloc[i]), (consolidation_end - 1, data['close'].iloc[consolidation_end - 1])],
                            confidence=0.6
                        )
                        patterns.append(pattern)
        
        return patterns
    
    def _calculate_trendline_slope(self, points: List[Tuple[int, float, str]]) -> float:
        """Calculate slope of trendline through points."""
        if len(points) < 2:
            return 0
        
        x_vals = [p[0] for p in points]
        y_vals = [p[1] for p in points]
        
        return np.polyfit(x_vals, y_vals, 1)[0]
    
    def _classify_triangle(self, high_slope: float, low_slope: float) -> Optional[PatternType]:
        """Classify triangle type based on trendline slopes."""
        slope_threshold = 0.00001
        
        if abs(high_slope) < slope_threshold and low_slope > slope_threshold:
            return PatternType.TRIANGLE_ASCENDING
        elif high_slope < -slope_threshold and abs(low_slope) < slope_threshold:
            return PatternType.TRIANGLE_DESCENDING
        elif high_slope < -slope_threshold and low_slope > slope_threshold:
            return PatternType.TRIANGLE_SYMMETRICAL
        
        return None
    
    def _calculate_hs_confidence(self, left: Tuple, head: Tuple, right: Tuple) -> float:
        """Calculate confidence for head and shoulders pattern."""
        # Higher confidence if shoulders are more equal and head is significantly higher
        shoulder_equality = 1 - abs(left[1] - right[1]) / max(left[1], right[1])
        head_prominence = (head[1] - max(left[1], right[1])) / head[1]
        
        return min(0.9, (shoulder_equality + head_prominence) / 2)
    
    def _calculate_double_pattern_confidence(self, first: Tuple, second: Tuple) -> float:
        """Calculate confidence for double top/bottom patterns."""
        price_equality = 1 - abs(first[1] - second[1]) / max(first[1], second[1])
        return min(0.9, price_equality)
    
    def _calculate_triangle_confidence(self, highs: List, lows: List) -> float:
        """Calculate confidence for triangle patterns."""
        # Simple confidence based on number of touch points
        return min(0.8, (len(highs) + len(lows)) / 6)
    
    def _calculate_triangle_target(self, data: pd.DataFrame, pivots: List, triangle_type: PatternType) -> float:
        """Calculate price target for triangle breakout."""
        # Simple target calculation - height of triangle added to breakout point
        prices = [p[1] for p in pivots]
        triangle_height = max(prices) - min(prices)
        
        current_price = data['close'].iloc[pivots[-1][0]]
        
        if triangle_type == PatternType.TRIANGLE_ASCENDING:
            return current_price + triangle_height
        else:
            return current_price - triangle_height