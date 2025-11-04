"""
Multi-timeframe analysis for forex pairs with pip interval tracking.
"""
from typing import Dict, List, Tuple
from dataclasses import dataclass
from datetime import datetime
import pandas as pd


@dataclass
class PipMovement:
    """Represents a pip movement within specified interval."""
    pair: str
    timeframe: str
    start_time: datetime
    end_time: datetime
    start_price: float
    end_price: float
    pip_change: float
    direction: str  # 'up' or 'down'


class MultiTimeframeAnalyzer:
    """Analyzes forex pairs across multiple timeframes with pip intervals."""
    
    def __init__(self, pair: str, pip_intervals: Tuple[int, int] = (20, 30)):
        self.pair = pair
        self.min_pips, self.max_pips = pip_intervals
        self.timeframes = ['M1', 'M5', 'M15', 'H1', 'H4', 'D1']
        self.pip_multiplier = self._get_pip_multiplier(pair)
    
    def _get_pip_multiplier(self, pair: str) -> float:
        """Get pip multiplier based on currency pair."""
        # JPY pairs have different pip calculation
        if 'JPY' in pair:
            return 0.01
        return 0.0001
    
    def calculate_pip_change(self, start_price: float, end_price: float) -> float:
        """Calculate pip change between two prices."""
        return (end_price - start_price) / self.pip_multiplier
    
    def analyze_timeframe(self, data: pd.DataFrame, timeframe: str) -> List[PipMovement]:
        """Analyze single timeframe for pip movements in specified interval."""
        movements = []
        
        for i in range(len(data) - 1):
            current_price = data.iloc[i]['close']
            
            # Look ahead for movements within pip range
            for j in range(i + 1, len(data)):
                future_price = data.iloc[j]['close']
                pip_change = abs(self.calculate_pip_change(current_price, future_price))
                
                if self.min_pips <= pip_change <= self.max_pips:
                    direction = 'up' if future_price > current_price else 'down'
                    
                    movement = PipMovement(
                        pair=self.pair,
                        timeframe=timeframe,
                        start_time=data.iloc[i]['timestamp'],
                        end_time=data.iloc[j]['timestamp'],
                        start_price=current_price,
                        end_price=future_price,
                        pip_change=pip_change,
                        direction=direction
                    )
                    movements.append(movement)
                    break
                elif pip_change > self.max_pips:
                    break
        
        return movements
    
    def analyze_all_timeframes(self, data_dict: Dict[str, pd.DataFrame]) -> Dict[str, List[PipMovement]]:
        """Analyze all timeframes and return movements for each."""
        results = {}
        
        for timeframe in self.timeframes:
            if timeframe in data_dict:
                results[timeframe] = self.analyze_timeframe(data_dict[timeframe], timeframe)
        
        return results
    
    def find_convergence_signals(self, movements_dict: Dict[str, List[PipMovement]]) -> List[Dict]:
        """Find signals where multiple timeframes show similar movements."""
        signals = []
        
        # Look for convergence across timeframes
        for tf1 in movements_dict:
            for tf2 in movements_dict:
                if tf1 != tf2:
                    # Find overlapping time periods with same direction
                    for mov1 in movements_dict[tf1]:
                        for mov2 in movements_dict[tf2]:
                            if (mov1.direction == mov2.direction and
                                self._time_overlap(mov1, mov2)):
                                
                                signals.append({
                                    'pair': self.pair,
                                    'timeframes': [tf1, tf2],
                                    'direction': mov1.direction,
                                    'strength': self._calculate_signal_strength(mov1, mov2),
                                    'timestamp': max(mov1.start_time, mov2.start_time)
                                })
        
        return signals
    
    def _time_overlap(self, mov1: PipMovement, mov2: PipMovement) -> bool:
        """Check if two movements have overlapping time periods."""
        return (mov1.start_time <= mov2.end_time and mov2.start_time <= mov1.end_time)
    
    def _calculate_signal_strength(self, mov1: PipMovement, mov2: PipMovement) -> float:
        """Calculate signal strength based on pip movements and timeframe correlation."""
        # Simple strength calculation - can be enhanced
        avg_pips = (mov1.pip_change + mov2.pip_change) / 2
        return min(avg_pips / self.max_pips, 1.0)