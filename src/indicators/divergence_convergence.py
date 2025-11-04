"""
Divergence and convergence analysis module.
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class DivergenceType(Enum):
    BULLISH_REGULAR = "bullish_regular"
    BEARISH_REGULAR = "bearish_regular"
    BULLISH_HIDDEN = "bullish_hidden"
    BEARISH_HIDDEN = "bearish_hidden"


class ConvergenceType(Enum):
    MACD_SIGNAL = "macd_signal"
    RSI_PRICE = "rsi_price"
    STOCH_PRICE = "stoch_price"
    MULTI_INDICATOR = "multi_indicator"


@dataclass
class Divergence:
    """Represents a divergence pattern."""
    divergence_type: DivergenceType
    start_idx: int
    end_idx: int
    price_points: List[Tuple[int, float]]  # Price swing points
    indicator_points: List[Tuple[int, float]]  # Indicator swing points
    strength: float  # 0.0 to 1.0
    
    @property
    def duration(self) -> int:
        return self.end_idx - self.start_idx


@dataclass
class Convergence:
    """Represents a convergence pattern."""
    convergence_type: ConvergenceType
    timestamp: int
    price: float
    indicators: Dict[str, float]
    strength: float
    signal_direction: str  # 'buy' or 'sell'


class DivergenceConvergenceAnalyzer:
    """Analyzes divergence and convergence patterns."""
    
    def __init__(self):
        self.rsi_period = 14
        self.macd_fast = 12
        self.macd_slow = 26
        self.macd_signal = 9
        self.stoch_k = 14
        self.stoch_d = 3
    
    def calculate_indicators(self, data: pd.DataFrame) -> pd.DataFrame:
        """Calculate technical indicators for divergence analysis."""
        df = data.copy()
        
        # RSI
        df['rsi'] = self._calculate_rsi(df['close'], self.rsi_period)
        
        # MACD
        macd_data = self._calculate_macd(df['close'], self.macd_fast, self.macd_slow, self.macd_signal)
        df['macd'] = macd_data['macd']
        df['macd_signal'] = macd_data['signal']
        df['macd_histogram'] = macd_data['histogram']
        
        # Stochastic
        stoch_data = self._calculate_stochastic(df['high'], df['low'], df['close'], self.stoch_k, self.stoch_d)
        df['stoch_k'] = stoch_data['%K']
        df['stoch_d'] = stoch_data['%D']
        
        return df
    
    def find_divergences(self, data: pd.DataFrame) -> List[Divergence]:
        """Find all types of divergences."""
        df = self.calculate_indicators(data)
        divergences = []
        
        # Find price and indicator swing points
        price_highs = self._find_swing_points(df['high'], 'high')
        price_lows = self._find_swing_points(df['low'], 'low')
        
        rsi_highs = self._find_swing_points(df['rsi'], 'high')
        rsi_lows = self._find_swing_points(df['rsi'], 'low')
        
        macd_highs = self._find_swing_points(df['macd'], 'high')
        macd_lows = self._find_swing_points(df['macd'], 'low')
        
        # Find RSI divergences
        divergences.extend(self._find_rsi_divergences(price_highs, price_lows, rsi_highs, rsi_lows, df))
        
        # Find MACD divergences
        divergences.extend(self._find_macd_divergences(price_highs, price_lows, macd_highs, macd_lows, df))
        
        return divergences
    
    def find_convergences(self, data: pd.DataFrame) -> List[Convergence]:
        """Find convergence signals across multiple indicators."""
        df = self.calculate_indicators(data)
        convergences = []
        
        for i in range(50, len(df)):  # Need history for reliable signals
            # MACD signal line crossover
            if self._is_macd_bullish_crossover(df, i):
                convergence = Convergence(
                    convergence_type=ConvergenceType.MACD_SIGNAL,
                    timestamp=i,
                    price=df['close'].iloc[i],
                    indicators={'macd': df['macd'].iloc[i], 'signal': df['macd_signal'].iloc[i]},
                    strength=self._calculate_macd_strength(df, i),
                    signal_direction='buy'
                )
                convergences.append(convergence)
            
            elif self._is_macd_bearish_crossover(df, i):
                convergence = Convergence(
                    convergence_type=ConvergenceType.MACD_SIGNAL,
                    timestamp=i,
                    price=df['close'].iloc[i],
                    indicators={'macd': df['macd'].iloc[i], 'signal': df['macd_signal'].iloc[i]},
                    strength=self._calculate_macd_strength(df, i),
                    signal_direction='sell'
                )
                convergences.append(convergence)
            
            # Multi-indicator convergence
            multi_signal = self._check_multi_indicator_convergence(df, i)
            if multi_signal:
                convergences.append(multi_signal)
        
        return convergences
    
    def _calculate_rsi(self, prices: pd.Series, period: int) -> pd.Series:
        """Calculate RSI indicator."""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def _calculate_macd(self, prices: pd.Series, fast: int, slow: int, signal: int) -> Dict[str, pd.Series]:
        """Calculate MACD indicator."""
        ema_fast = prices.ewm(span=fast).mean()
        ema_slow = prices.ewm(span=slow).mean()
        
        macd = ema_fast - ema_slow
        signal_line = macd.ewm(span=signal).mean()
        histogram = macd - signal_line
        
        return {
            'macd': macd,
            'signal': signal_line,
            'histogram': histogram
        }
    
    def _calculate_stochastic(self, high: pd.Series, low: pd.Series, close: pd.Series, k_period: int, d_period: int) -> Dict[str, pd.Series]:
        """Calculate Stochastic oscillator."""
        lowest_low = low.rolling(window=k_period).min()
        highest_high = high.rolling(window=k_period).max()
        
        k_percent = 100 * ((close - lowest_low) / (highest_high - lowest_low))
        d_percent = k_percent.rolling(window=d_period).mean()
        
        return {
            '%K': k_percent,
            '%D': d_percent
        }
    
    def _find_swing_points(self, series: pd.Series, point_type: str, window: int = 5) -> List[Tuple[int, float]]:
        """Find swing highs or lows in a series."""
        points = []
        
        for i in range(window, len(series) - window):
            if pd.isna(series.iloc[i]):
                continue
            
            if point_type == 'high':
                if all(series.iloc[i] >= series.iloc[i-j] for j in range(1, window+1)) and \
                   all(series.iloc[i] >= series.iloc[i+j] for j in range(1, window+1)):
                    points.append((i, series.iloc[i]))
            
            elif point_type == 'low':
                if all(series.iloc[i] <= series.iloc[i-j] for j in range(1, window+1)) and \
                   all(series.iloc[i] <= series.iloc[i+j] for j in range(1, window+1)):
                    points.append((i, series.iloc[i]))
        
        return points
    
    def _find_rsi_divergences(self, price_highs: List, price_lows: List, rsi_highs: List, rsi_lows: List, df: pd.DataFrame) -> List[Divergence]:
        """Find RSI divergences."""
        divergences = []
        
        # Bearish divergence (price makes higher high, RSI makes lower high)
        for i in range(len(price_highs) - 1):
            for j in range(len(rsi_highs) - 1):
                ph1, ph2 = price_highs[i], price_highs[i + 1]
                rh1, rh2 = rsi_highs[j], rsi_highs[j + 1]
                
                # Check if time periods align
                if abs(ph1[0] - rh1[0]) <= 5 and abs(ph2[0] - rh2[0]) <= 5:
                    if ph2[1] > ph1[1] and rh2[1] < rh1[1]:  # Bearish divergence
                        divergence = Divergence(
                            divergence_type=DivergenceType.BEARISH_REGULAR,
                            start_idx=min(ph1[0], rh1[0]),
                            end_idx=max(ph2[0], rh2[0]),
                            price_points=[ph1, ph2],
                            indicator_points=[rh1, rh2],
                            strength=self._calculate_divergence_strength(ph1, ph2, rh1, rh2)
                        )
                        divergences.append(divergence)
        
        # Bullish divergence (price makes lower low, RSI makes higher low)
        for i in range(len(price_lows) - 1):
            for j in range(len(rsi_lows) - 1):
                pl1, pl2 = price_lows[i], price_lows[i + 1]
                rl1, rl2 = rsi_lows[j], rsi_lows[j + 1]
                
                if abs(pl1[0] - rl1[0]) <= 5 and abs(pl2[0] - rl2[0]) <= 5:
                    if pl2[1] < pl1[1] and rl2[1] > rl1[1]:  # Bullish divergence
                        divergence = Divergence(
                            divergence_type=DivergenceType.BULLISH_REGULAR,
                            start_idx=min(pl1[0], rl1[0]),
                            end_idx=max(pl2[0], rl2[0]),
                            price_points=[pl1, pl2],
                            indicator_points=[rl1, rl2],
                            strength=self._calculate_divergence_strength(pl1, pl2, rl1, rl2)
                        )
                        divergences.append(divergence)
        
        return divergences
    
    def _find_macd_divergences(self, price_highs: List, price_lows: List, macd_highs: List, macd_lows: List, df: pd.DataFrame) -> List[Divergence]:
        """Find MACD divergences."""
        divergences = []
        
        # Similar logic to RSI divergences but with MACD
        # Bearish divergence
        for i in range(len(price_highs) - 1):
            for j in range(len(macd_highs) - 1):
                ph1, ph2 = price_highs[i], price_highs[i + 1]
                mh1, mh2 = macd_highs[j], macd_highs[j + 1]
                
                if abs(ph1[0] - mh1[0]) <= 5 and abs(ph2[0] - mh2[0]) <= 5:
                    if ph2[1] > ph1[1] and mh2[1] < mh1[1]:
                        divergence = Divergence(
                            divergence_type=DivergenceType.BEARISH_REGULAR,
                            start_idx=min(ph1[0], mh1[0]),
                            end_idx=max(ph2[0], mh2[0]),
                            price_points=[ph1, ph2],
                            indicator_points=[mh1, mh2],
                            strength=self._calculate_divergence_strength(ph1, ph2, mh1, mh2)
                        )
                        divergences.append(divergence)
        
        return divergences
    
    def _is_macd_bullish_crossover(self, df: pd.DataFrame, idx: int) -> bool:
        """Check for MACD bullish signal line crossover."""
        if idx < 1:
            return False
        
        return (df['macd'].iloc[idx] > df['macd_signal'].iloc[idx] and
                df['macd'].iloc[idx-1] <= df['macd_signal'].iloc[idx-1])
    
    def _is_macd_bearish_crossover(self, df: pd.DataFrame, idx: int) -> bool:
        """Check for MACD bearish signal line crossover."""
        if idx < 1:
            return False
        
        return (df['macd'].iloc[idx] < df['macd_signal'].iloc[idx] and
                df['macd'].iloc[idx-1] >= df['macd_signal'].iloc[idx-1])
    
    def _check_multi_indicator_convergence(self, df: pd.DataFrame, idx: int) -> Optional[Convergence]:
        """Check for convergence across multiple indicators."""
        if idx < 20:  # Need sufficient history
            return None
        
        # Check if multiple indicators align
        rsi = df['rsi'].iloc[idx]
        macd = df['macd'].iloc[idx]
        macd_signal = df['macd_signal'].iloc[idx]
        stoch_k = df['stoch_k'].iloc[idx]
        
        # Bullish convergence
        if (rsi < 30 and  # RSI oversold
            macd > macd_signal and  # MACD above signal
            stoch_k < 20):  # Stochastic oversold
            
            return Convergence(
                convergence_type=ConvergenceType.MULTI_INDICATOR,
                timestamp=idx,
                price=df['close'].iloc[idx],
                indicators={'rsi': rsi, 'macd': macd, 'stoch_k': stoch_k},
                strength=0.8,
                signal_direction='buy'
            )
        
        # Bearish convergence
        elif (rsi > 70 and  # RSI overbought
              macd < macd_signal and  # MACD below signal
              stoch_k > 80):  # Stochastic overbought
            
            return Convergence(
                convergence_type=ConvergenceType.MULTI_INDICATOR,
                timestamp=idx,
                price=df['close'].iloc[idx],
                indicators={'rsi': rsi, 'macd': macd, 'stoch_k': stoch_k},
                strength=0.8,
                signal_direction='sell'
            )
        
        return None
    
    def _calculate_divergence_strength(self, p1: Tuple, p2: Tuple, i1: Tuple, i2: Tuple) -> float:
        """Calculate strength of divergence pattern."""
        # Price change magnitude
        price_change = abs(p2[1] - p1[1]) / p1[1]
        
        # Indicator change magnitude
        indicator_change = abs(i2[1] - i1[1]) / abs(i1[1]) if i1[1] != 0 else 0
        
        # Time alignment (closer = stronger)
        time_alignment = 1 - (abs(p1[0] - i1[0]) + abs(p2[0] - i2[0])) / 20
        
        return min(1.0, (price_change + indicator_change + time_alignment) / 3)
    
    def _calculate_macd_strength(self, df: pd.DataFrame, idx: int) -> float:
        """Calculate MACD signal strength."""
        macd_diff = abs(df['macd'].iloc[idx] - df['macd_signal'].iloc[idx])
        histogram = abs(df['macd_histogram'].iloc[idx])
        
        # Normalize by recent volatility
        recent_volatility = df['close'].iloc[max(0, idx-20):idx].std()
        
        return min(1.0, (macd_diff + histogram) / recent_volatility if recent_volatility > 0 else 0.5)