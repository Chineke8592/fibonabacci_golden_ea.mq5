"""
Elliott Wave analysis for identifying impulsive and corrective wave patterns.
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class WaveType(Enum):
    IMPULSE = "impulse"
    CORRECTION = "correction"
    UNKNOWN = "unknown"


class WaveDirection(Enum):
    UP = "up"
    DOWN = "down"


@dataclass
class Wave:
    """Represents an Elliott Wave."""
    start_idx: int
    end_idx: int
    start_price: float
    end_price: float
    wave_type: WaveType
    direction: WaveDirection
    degree: int  # Wave degree (1=minor, 2=intermediate, 3=primary, etc.)
    label: str  # Wave label (1, 2, 3, 4, 5, A, B, C)
    
    @property
    def length(self) -> float:
        """Calculate wave length in price points."""
        return abs(self.end_price - self.start_price)
    
    @property
    def duration(self) -> int:
        """Calculate wave duration in periods."""
        return self.end_idx - self.start_idx


class ElliottWaveAnalyzer:
    """Analyzes price data for Elliott Wave patterns."""
    
    def __init__(self, min_wave_length: float = 0.001):
        self.min_wave_length = min_wave_length
        self.fibonacci_ratios = [0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.272, 1.618, 2.618]
    
    def find_pivot_points(self, data: pd.DataFrame, window: int = 5) -> List[Tuple[int, float, str]]:
        """Find swing highs and lows (pivot points)."""
        highs = data['high'].rolling(window=window*2+1, center=True).max()
        lows = data['low'].rolling(window=window*2+1, center=True).min()
        
        pivots = []
        
        for i in range(window, len(data) - window):
            if data['high'].iloc[i] == highs.iloc[i]:
                pivots.append((i, data['high'].iloc[i], 'high'))
            elif data['low'].iloc[i] == lows.iloc[i]:
                pivots.append((i, data['low'].iloc[i], 'low'))
        
        return pivots
    
    def identify_impulse_waves(self, pivots: List[Tuple[int, float, str]]) -> List[Wave]:
        """Identify 5-wave impulse patterns."""
        impulse_waves = []
        
        # Look for 5-wave patterns (alternating high-low or low-high)
        for i in range(len(pivots) - 4):
            sequence = pivots[i:i+5]
            
            # Check for valid 5-wave structure
            if self._is_valid_impulse_sequence(sequence):
                waves = self._create_impulse_waves(sequence)
                impulse_waves.extend(waves)
        
        return impulse_waves
    
    def identify_corrective_waves(self, pivots: List[Tuple[int, float, str]]) -> List[Wave]:
        """Identify 3-wave corrective patterns (ABC)."""
        corrective_waves = []
        
        # Look for 3-wave patterns
        for i in range(len(pivots) - 2):
            sequence = pivots[i:i+3]
            
            if self._is_valid_corrective_sequence(sequence):
                waves = self._create_corrective_waves(sequence)
                corrective_waves.extend(waves)
        
        return corrective_waves
    
    def _is_valid_impulse_sequence(self, sequence: List[Tuple[int, float, str]]) -> bool:
        """Check if sequence forms valid 5-wave impulse pattern."""
        if len(sequence) != 5:
            return False
        
        # Check alternating pattern
        types = [s[2] for s in sequence]
        
        # Should alternate: high-low-high-low-high or low-high-low-high-low
        pattern1 = ['high', 'low', 'high', 'low', 'high']
        pattern2 = ['low', 'high', 'low', 'high', 'low']
        
        if types not in [pattern1, pattern2]:
            return False
        
        # Check Elliott Wave rules
        prices = [s[1] for s in sequence]
        
        if types == pattern1:  # Upward impulse
            # Wave 3 should not be shortest
            wave1 = abs(prices[1] - prices[0])
            wave3 = abs(prices[3] - prices[2])
            wave5 = abs(prices[4] - prices[3])
            
            if wave3 < wave1 and wave3 < wave5:
                return False
            
            # Wave 4 should not overlap wave 1
            if prices[3] <= prices[1]:
                return False
        
        return True
    
    def _is_valid_corrective_sequence(self, sequence: List[Tuple[int, float, str]]) -> bool:
        """Check if sequence forms valid 3-wave corrective pattern."""
        if len(sequence) != 3:
            return False
        
        types = [s[2] for s in sequence]
        
        # Should alternate: high-low-high or low-high-low
        pattern1 = ['high', 'low', 'high']
        pattern2 = ['low', 'high', 'low']
        
        return types in [pattern1, pattern2]
    
    def _create_impulse_waves(self, sequence: List[Tuple[int, float, str]]) -> List[Wave]:
        """Create Wave objects for impulse pattern."""
        waves = []
        direction = WaveDirection.UP if sequence[0][2] == 'low' else WaveDirection.DOWN
        
        for i in range(4):  # 4 waves in 5-point sequence
            start_idx, start_price, _ = sequence[i]
            end_idx, end_price, _ = sequence[i + 1]
            
            wave = Wave(
                start_idx=start_idx,
                end_idx=end_idx,
                start_price=start_price,
                end_price=end_price,
                wave_type=WaveType.IMPULSE,
                direction=direction,
                degree=1,
                label=str((i % 5) + 1)  # Labels 1, 2, 3, 4, 5
            )
            waves.append(wave)
            
            # Alternate direction for corrective waves (2, 4)
            if i in [0, 2]:  # After waves 1 and 3
                direction = WaveDirection.DOWN if direction == WaveDirection.UP else WaveDirection.UP
        
        return waves
    
    def _create_corrective_waves(self, sequence: List[Tuple[int, float, str]]) -> List[Wave]:
        """Create Wave objects for corrective pattern."""
        waves = []
        direction = WaveDirection.DOWN if sequence[0][2] == 'high' else WaveDirection.UP
        labels = ['A', 'B', 'C']
        
        for i in range(2):  # 2 waves in 3-point sequence
            start_idx, start_price, _ = sequence[i]
            end_idx, end_price, _ = sequence[i + 1]
            
            wave = Wave(
                start_idx=start_idx,
                end_idx=end_idx,
                start_price=start_price,
                end_price=end_price,
                wave_type=WaveType.CORRECTION,
                direction=direction,
                degree=1,
                label=labels[i]
            )
            waves.append(wave)
            
            # Alternate direction
            direction = WaveDirection.UP if direction == WaveDirection.DOWN else WaveDirection.DOWN
        
        return waves
    
    def calculate_fibonacci_levels(self, wave: Wave) -> Dict[str, float]:
        """Calculate Fibonacci retracement and extension levels for a wave."""
        levels = {}
        wave_range = wave.end_price - wave.start_price
        
        # Retracement levels
        for ratio in self.fibonacci_ratios:
            if wave.direction == WaveDirection.UP:
                levels[f"ret_{ratio}"] = wave.end_price - (wave_range * ratio)
            else:
                levels[f"ret_{ratio}"] = wave.end_price + (wave_range * ratio)
        
        # Extension levels
        for ratio in [1.272, 1.618, 2.618]:
            if wave.direction == WaveDirection.UP:
                levels[f"ext_{ratio}"] = wave.end_price + (wave_range * ratio)
            else:
                levels[f"ext_{ratio}"] = wave.end_price - (wave_range * ratio)
        
        return levels
    
    def analyze_wave_structure(self, data: pd.DataFrame) -> Dict[str, List[Wave]]:
        """Complete Elliott Wave analysis of price data."""
        pivots = self.find_pivot_points(data)
        
        impulse_waves = self.identify_impulse_waves(pivots)
        corrective_waves = self.identify_corrective_waves(pivots)
        
        return {
            'impulse': impulse_waves,
            'corrective': corrective_waves,
            'pivots': pivots
        }