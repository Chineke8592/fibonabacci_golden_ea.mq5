"""
Enhanced Elliott Wave Counter with detailed wave identification.
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class WaveDegree(Enum):
    """Elliott Wave degrees from smallest to largest."""
    SUBMINUETTE = "Subminuette"
    MINUETTE = "Minuette"
    MINUTE = "Minute"
    MINOR = "Minor"
    INTERMEDIATE = "Intermediate"
    PRIMARY = "Primary"
    CYCLE = "Cycle"
    SUPERCYCLE = "Supercycle"


@dataclass
class WaveCount:
    """Detailed wave count information."""
    wave_number: str  # "1", "2", "3", "4", "5", "A", "B", "C"
    wave_type: str  # "impulse" or "correction"
    degree: WaveDegree
    start_idx: int
    end_idx: int
    start_price: float
    end_price: float
    start_time: pd.Timestamp
    end_time: pd.Timestamp
    direction: str  # "up" or "down"
    length_points: float
    length_percent: float
    fibonacci_ratio: Optional[float] = None
    parent_wave: Optional[str] = None
    
    def __str__(self):
        return f"Wave {self.wave_number} ({self.wave_type}): {self.direction} from {self.start_price:.5f} to {self.end_price:.5f}"


class WaveCounter:
    """Enhanced Elliott Wave counter with detailed identification."""
    
    def __init__(self, sensitivity: int = 5):
        self.sensitivity = sensitivity
        self.fibonacci_ratios = {
            'wave_2_retracement': [0.382, 0.5, 0.618],
            'wave_3_extension': [1.618, 2.618],
            'wave_4_retracement': [0.236, 0.382],
            'wave_5_extension': [0.618, 1.0, 1.618],
            'wave_c_extension': [1.0, 1.618]
        }
    
    def identify_wave_counts(self, data: pd.DataFrame) -> List[WaveCount]:
        """Identify and count all Elliott Waves in the data."""
        # Find all pivot points
        pivots = self._find_zigzag_pivots(data)
        
        if len(pivots) < 5:
            return []
        
        wave_counts = []
        
        # Identify impulse waves (5-wave patterns)
        impulse_waves = self._identify_impulse_waves(pivots, data)
        wave_counts.extend(impulse_waves)
        
        # Identify corrective waves (3-wave patterns)
        corrective_waves = self._identify_corrective_waves(pivots, data)
        wave_counts.extend(corrective_waves)
        
        # Sort by start index
        wave_counts.sort(key=lambda w: w.start_idx)
        
        return wave_counts
    
    def _find_zigzag_pivots(self, data: pd.DataFrame) -> List[Tuple[int, float, str]]:
        """Find zigzag pivot points (swing highs and lows)."""
        pivots = []
        window = self.sensitivity
        
        for i in range(window, len(data) - window):
            # Check for swing high
            is_high = True
            for j in range(1, window + 1):
                if data['high'].iloc[i] < data['high'].iloc[i-j] or \
                   data['high'].iloc[i] < data['high'].iloc[i+j]:
                    is_high = False
                    break
            
            if is_high:
                pivots.append((i, data['high'].iloc[i], 'high'))
                continue
            
            # Check for swing low
            is_low = True
            for j in range(1, window + 1):
                if data['low'].iloc[i] > data['low'].iloc[i-j] or \
                   data['low'].iloc[i] > data['low'].iloc[i+j]:
                    is_low = False
                    break
            
            if is_low:
                pivots.append((i, data['low'].iloc[i], 'low'))
        
        return pivots
    
    def _identify_impulse_waves(self, pivots: List[Tuple], data: pd.DataFrame) -> List[WaveCount]:
        """Identify 5-wave impulse patterns."""
        impulse_waves = []
        
        # Need at least 5 pivots for a complete impulse
        for i in range(len(pivots) - 4):
            sequence = pivots[i:i+5]
            
            # Check if this is a valid impulse sequence
            if self._is_valid_impulse(sequence):
                waves = self._create_impulse_count(sequence, data)
                impulse_waves.extend(waves)
        
        return impulse_waves
    
    def _is_valid_impulse(self, sequence: List[Tuple]) -> bool:
        """Validate if sequence forms a proper 5-wave impulse."""
        if len(sequence) != 5:
            return False
        
        types = [s[2] for s in sequence]
        prices = [s[1] for s in sequence]
        
        # Check for alternating pattern
        upward_impulse = types == ['low', 'high', 'low', 'high', 'low']
        downward_impulse = types == ['high', 'low', 'high', 'low', 'high']
        
        if not (upward_impulse or downward_impulse):
            return False
        
        # Apply Elliott Wave rules
        if upward_impulse:
            # Wave 3 cannot be the shortest
            wave1 = prices[1] - prices[0]
            wave3 = prices[3] - prices[2]
            wave5 = prices[4] - prices[3]
            
            if wave3 < wave1 and wave3 < wave5:
                return False
            
            # Wave 4 cannot overlap Wave 1
            if prices[3] <= prices[1]:
                return False
            
            # Wave 2 cannot retrace beyond start of Wave 1
            if prices[2] <= prices[0]:
                return False
        
        elif downward_impulse:
            # Similar rules for downward impulse
            wave1 = prices[0] - prices[1]
            wave3 = prices[2] - prices[3]
            wave5 = prices[3] - prices[4]
            
            if wave3 < wave1 and wave3 < wave5:
                return False
            
            if prices[3] >= prices[1]:
                return False
            
            if prices[2] >= prices[0]:
                return False
        
        return True
    
    def _create_impulse_count(self, sequence: List[Tuple], data: pd.DataFrame) -> List[WaveCount]:
        """Create detailed wave count for impulse pattern."""
        waves = []
        is_upward = sequence[0][2] == 'low'
        
        wave_labels = ['1', '2', '3', '4', '5']
        
        for idx, label in enumerate(wave_labels):
            if idx >= len(sequence) - 1:
                break
            
            start_idx, start_price, _ = sequence[idx]
            end_idx, end_price, _ = sequence[idx + 1]
            
            direction = 'up' if end_price > start_price else 'down'
            length_points = abs(end_price - start_price)
            length_percent = (length_points / start_price) * 100
            
            # Calculate Fibonacci ratio if applicable
            fib_ratio = None
            if idx > 0:
                prev_wave_length = abs(sequence[idx][1] - sequence[idx-1][1])
                if prev_wave_length > 0:
                    fib_ratio = length_points / prev_wave_length
            
            wave = WaveCount(
                wave_number=label,
                wave_type='impulse',
                degree=self._determine_degree(length_points, data),
                start_idx=start_idx,
                end_idx=end_idx,
                start_price=start_price,
                end_price=end_price,
                start_time=data.index[start_idx] if hasattr(data.index, '__getitem__') else data['timestamp'].iloc[start_idx],
                end_time=data.index[end_idx] if hasattr(data.index, '__getitem__') else data['timestamp'].iloc[end_idx],
                direction=direction,
                length_points=length_points,
                length_percent=length_percent,
                fibonacci_ratio=fib_ratio
            )
            
            waves.append(wave)
        
        return waves
    
    def _identify_corrective_waves(self, pivots: List[Tuple], data: pd.DataFrame) -> List[WaveCount]:
        """Identify 3-wave corrective patterns (ABC)."""
        corrective_waves = []
        
        # Need at least 3 pivots for a correction
        for i in range(len(pivots) - 2):
            sequence = pivots[i:i+3]
            
            if self._is_valid_correction(sequence):
                waves = self._create_corrective_count(sequence, data)
                corrective_waves.extend(waves)
        
        return corrective_waves
    
    def _is_valid_correction(self, sequence: List[Tuple]) -> bool:
        """Validate if sequence forms a proper ABC correction."""
        if len(sequence) != 3:
            return False
        
        types = [s[2] for s in sequence]
        
        # Check for alternating pattern
        zigzag_up = types == ['low', 'high', 'low']
        zigzag_down = types == ['high', 'low', 'high']
        
        return zigzag_up or zigzag_down
    
    def _create_corrective_count(self, sequence: List[Tuple], data: pd.DataFrame) -> List[WaveCount]:
        """Create detailed wave count for corrective pattern."""
        waves = []
        wave_labels = ['A', 'B', 'C']
        
        for idx, label in enumerate(wave_labels):
            if idx >= len(sequence) - 1:
                break
            
            start_idx, start_price, _ = sequence[idx]
            end_idx, end_price, _ = sequence[idx + 1]
            
            direction = 'up' if end_price > start_price else 'down'
            length_points = abs(end_price - start_price)
            length_percent = (length_points / start_price) * 100
            
            # Calculate Fibonacci ratio
            fib_ratio = None
            if idx == 2:  # Wave C
                wave_a_length = abs(sequence[1][1] - sequence[0][1])
                if wave_a_length > 0:
                    fib_ratio = length_points / wave_a_length
            
            wave = WaveCount(
                wave_number=label,
                wave_type='correction',
                degree=self._determine_degree(length_points, data),
                start_idx=start_idx,
                end_idx=end_idx,
                start_price=start_price,
                end_price=end_price,
                start_time=data.index[start_idx] if hasattr(data.index, '__getitem__') else data['timestamp'].iloc[start_idx],
                end_time=data.index[end_idx] if hasattr(data.index, '__getitem__') else data['timestamp'].iloc[end_idx],
                direction=direction,
                length_points=length_points,
                length_percent=length_percent,
                fibonacci_ratio=fib_ratio
            )
            
            waves.append(wave)
        
        return waves
    
    def _determine_degree(self, wave_length: float, data: pd.DataFrame) -> WaveDegree:
        """Determine wave degree based on length and timeframe."""
        # Calculate average price range
        avg_range = data['close'].std()
        
        ratio = wave_length / avg_range if avg_range > 0 else 0
        
        if ratio > 5:
            return WaveDegree.PRIMARY
        elif ratio > 3:
            return WaveDegree.INTERMEDIATE
        elif ratio > 2:
            return WaveDegree.MINOR
        elif ratio > 1:
            return WaveDegree.MINUTE
        else:
            return WaveDegree.MINUETTE
    
    def get_wave_summary(self, wave_counts: List[WaveCount]) -> Dict:
        """Generate summary of wave counts."""
        impulse_waves = [w for w in wave_counts if w.wave_type == 'impulse']
        corrective_waves = [w for w in wave_counts if w.wave_type == 'correction']
        
        # Count by wave number
        wave_numbers = {}
        for wave in wave_counts:
            if wave.wave_number not in wave_numbers:
                wave_numbers[wave.wave_number] = 0
            wave_numbers[wave.wave_number] += 1
        
        return {
            'total_waves': len(wave_counts),
            'impulse_count': len(impulse_waves),
            'corrective_count': len(corrective_waves),
            'wave_numbers': wave_numbers,
            'impulse_waves': impulse_waves,
            'corrective_waves': corrective_waves
        }
    
    def print_wave_analysis(self, wave_counts: List[WaveCount], pair: str = ""):
        """Print detailed wave analysis."""
        summary = self.get_wave_summary(wave_counts)
        
        print(f"\n{'='*70}")
        print(f"ELLIOTT WAVE COUNT ANALYSIS {f'- {pair}' if pair else ''}")
        print(f"{'='*70}")
        
        print(f"\nWave Summary:")
        print(f"   Total Waves Identified: {summary['total_waves']}")
        print(f"   Impulse Waves (1-2-3-4-5): {summary['impulse_count']}")
        print(f"   Corrective Waves (A-B-C): {summary['corrective_count']}")
        
        # Print impulse waves
        if summary['impulse_waves']:
            print(f"\nIMPULSE WAVES (Motive):")
            print(f"   {'Wave':<6} {'Type':<12} {'Direction':<10} {'Price Range':<25} {'Length %':<12} {'Fib Ratio':<10}")
            print(f"   {'-'*85}")
            
            for wave in summary['impulse_waves'][:10]:  # Show first 10
                fib_str = f"{wave.fibonacci_ratio:.3f}" if wave.fibonacci_ratio else "N/A"
                print(f"   {wave.wave_number:<6} {wave.degree.value:<12} {wave.direction:<10} "
                      f"{wave.start_price:.5f} → {wave.end_price:.5f}  {wave.length_percent:>6.2f}%    {fib_str:<10}")
        
        # Print corrective waves
        if summary['corrective_waves']:
            print(f"\nCORRECTIVE WAVES:")
            print(f"   {'Wave':<6} {'Type':<12} {'Direction':<10} {'Price Range':<25} {'Length %':<12} {'Fib Ratio':<10}")
            print(f"   {'-'*85}")
            
            for wave in summary['corrective_waves'][:10]:  # Show first 10
                fib_str = f"{wave.fibonacci_ratio:.3f}" if wave.fibonacci_ratio else "N/A"
                print(f"   {wave.wave_number:<6} {wave.degree.value:<12} {wave.direction:<10} "
                      f"{wave.start_price:.5f} → {wave.end_price:.5f}  {wave.length_percent:>6.2f}%    {fib_str:<10}")
        
        # Wave count distribution
        print(f"\nWave Count Distribution:")
        for wave_num, count in sorted(summary['wave_numbers'].items()):
            print(f"   Wave {wave_num}: {count} occurrences")
        
        print(f"\n{'='*70}\n")