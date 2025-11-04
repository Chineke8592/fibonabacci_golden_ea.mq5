"""
Visualization module for displaying analysis results.
"""
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from typing import List, Dict, Optional
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from indicators.elliott_wave import Wave, WaveType
from indicators.trend_analysis import TrendMove
from indicators.chart_patterns import ChartPattern
from indicators.divergence_convergence import Divergence, Convergence


class ForexChartVisualizer:
    """Creates comprehensive forex analysis charts."""
    
    def __init__(self, figsize: tuple = (15, 10)):
        self.figsize = figsize
        plt.style.use('dark_background')
    
    def plot_comprehensive_analysis(self, data: pd.DataFrame, 
                                  waves: List[Wave] = None,
                                  trends: List[TrendMove] = None,
                                  patterns: List[ChartPattern] = None,
                                  divergences: List[Divergence] = None,
                                  convergences: List[Convergence] = None,
                                  pair: str = "FOREX"):
        """Create comprehensive analysis chart with all indicators."""
        
        fig = make_subplots(
            rows=4, cols=1,
            shared_xaxes=True,
            vertical_spacing=0.05,
            subplot_titles=[
                f'{pair} - Price Action with Elliott Waves & Patterns',
                'RSI with Divergences',
                'MACD with Convergences',
                'Volume'
            ],
            row_heights=[0.5, 0.2, 0.2, 0.1]
        )
        
        # Main price chart
        self._add_candlestick_chart(fig, data, row=1)
        
        # Add Elliott Waves
        if waves:
            self._add_elliott_waves(fig, waves, row=1)
        
        # Add trend lines
        if trends:
            self._add_trend_lines(fig, trends, data, row=1)
        
        # Add chart patterns
        if patterns:
            self._add_chart_patterns(fig, patterns, data, row=1)
        
        # RSI subplot with divergences
        self._add_rsi_chart(fig, data, divergences, row=2)
        
        # MACD subplot with convergences
        self._add_macd_chart(fig, data, convergences, row=3)
        
        # Volume subplot
        self._add_volume_chart(fig, data, row=4)
        
        # Update layout
        fig.update_layout(
            title=f"Comprehensive Forex Analysis - {pair}",
            xaxis_rangeslider_visible=False,
            height=800,
            showlegend=True,
            template="plotly_dark"
        )
        
        return fig
    
    def _add_candlestick_chart(self, fig, data: pd.DataFrame, row: int):
        """Add candlestick chart to subplot."""
        fig.add_trace(
            go.Candlestick(
                x=data.index,
                open=data['open'],
                high=data['high'],
                low=data['low'],
                close=data['close'],
                name="Price",
                increasing_line_color='#00ff00',
                decreasing_line_color='#ff0000'
            ),
            row=row, col=1
        )
    
    def _add_elliott_waves(self, fig, waves: List[Wave], row: int):
        """Add Elliott Wave annotations."""
        colors = {
            WaveType.IMPULSE: '#ffff00',  # Yellow for impulse
            WaveType.CORRECTION: '#ff8800'  # Orange for correction
        }
        
        for wave in waves[:10]:  # Limit to first 10 waves
            color = colors.get(wave.wave_type, '#ffffff')
            
            # Add wave line
            fig.add_trace(
                go.Scatter(
                    x=[wave.start_idx, wave.end_idx],
                    y=[wave.start_price, wave.end_price],
                    mode='lines+markers+text',
                    line=dict(color=color, width=2),
                    text=['', wave.label],
                    textposition='middle center',
                    name=f"Wave {wave.label} ({wave.wave_type.value})",
                    showlegend=False
                ),
                row=row, col=1
            )
    
    def _add_trend_lines(self, fig, trends: List[TrendMove], data: pd.DataFrame, row: int):
        """Add trend lines to chart."""
        colors = {
            'uptrend': '#00ff00',
            'downtrend': '#ff0000',
            'sideways': '#ffff00'
        }
        
        for i, trend in enumerate(trends[:5]):  # Limit to first 5 trends
            color = colors.get(trend.direction.value, '#ffffff')
            
            fig.add_trace(
                go.Scatter(
                    x=[trend.start_idx, trend.end_idx],
                    y=[trend.start_price, trend.end_price],
                    mode='lines',
                    line=dict(color=color, width=3, dash='dash'),
                    name=f"Trend {i+1} ({trend.direction.value})",
                    showlegend=False
                ),
                row=row, col=1
            )
    
    def _add_chart_patterns(self, fig, patterns: List[ChartPattern], data: pd.DataFrame, row: int):
        """Add chart pattern annotations."""
        for pattern in patterns[:3]:  # Limit to first 3 patterns
            # Add pattern boundary box
            pattern_data = data.iloc[pattern.start_idx:pattern.end_idx+1]
            
            fig.add_shape(
                type="rect",
                x0=pattern.start_idx,
                y0=pattern_data['low'].min(),
                x1=pattern.end_idx,
                y1=pattern_data['high'].max(),
                line=dict(color="cyan", width=2, dash="dot"),
                fillcolor="rgba(0,255,255,0.1)",
                row=row, col=1
            )
            
            # Add pattern label
            fig.add_annotation(
                x=(pattern.start_idx + pattern.end_idx) / 2,
                y=pattern_data['high'].max(),
                text=f"{pattern.pattern_type.value}<br>Conf: {pattern.confidence:.2f}",
                showarrow=True,
                arrowhead=2,
                arrowcolor="cyan",
                bgcolor="rgba(0,0,0,0.8)",
                bordercolor="cyan",
                row=row, col=1
            )
    
    def _add_rsi_chart(self, fig, data: pd.DataFrame, divergences: List[Divergence], row: int):
        """Add RSI chart with divergence markers."""
        # Calculate RSI
        rsi = self._calculate_rsi(data['close'])
        
        fig.add_trace(
            go.Scatter(
                x=data.index,
                y=rsi,
                mode='lines',
                line=dict(color='purple', width=2),
                name='RSI'
            ),
            row=row, col=1
        )
        
        # Add overbought/oversold lines
        fig.add_hline(y=70, line_dash="dash", line_color="red", row=row, col=1)
        fig.add_hline(y=30, line_dash="dash", line_color="green", row=row, col=1)
        
        # Add divergence markers
        if divergences:
            for div in divergences[:3]:
                if 'rsi' in str(div.divergence_type.value).lower():
                    color = 'lime' if 'bullish' in div.divergence_type.value else 'red'
                    
                    fig.add_trace(
                        go.Scatter(
                            x=[div.start_idx, div.end_idx],
                            y=[rsi.iloc[div.start_idx], rsi.iloc[div.end_idx]],
                            mode='lines+markers',
                            line=dict(color=color, width=3),
                            name=f"RSI {div.divergence_type.value}",
                            showlegend=False
                        ),
                        row=row, col=1
                    )
    
    def _add_macd_chart(self, fig, data: pd.DataFrame, convergences: List[Convergence], row: int):
        """Add MACD chart with convergence signals."""
        # Calculate MACD
        macd_data = self._calculate_macd(data['close'])
        
        fig.add_trace(
            go.Scatter(
                x=data.index,
                y=macd_data['macd'],
                mode='lines',
                line=dict(color='blue', width=2),
                name='MACD'
            ),
            row=row, col=1
        )
        
        fig.add_trace(
            go.Scatter(
                x=data.index,
                y=macd_data['signal'],
                mode='lines',
                line=dict(color='red', width=1),
                name='Signal'
            ),
            row=row, col=1
        )
        
        # Add histogram
        fig.add_trace(
            go.Bar(
                x=data.index,
                y=macd_data['histogram'],
                name='Histogram',
                marker_color='gray',
                opacity=0.6
            ),
            row=row, col=1
        )
        
        # Add convergence signals
        if convergences:
            for conv in convergences:
                if 'macd' in conv.convergence_type.value:
                    color = 'lime' if conv.signal_direction == 'buy' else 'red'
                    
                    fig.add_trace(
                        go.Scatter(
                            x=[conv.timestamp],
                            y=[macd_data['macd'].iloc[conv.timestamp]],
                            mode='markers',
                            marker=dict(color=color, size=10, symbol='triangle-up' if conv.signal_direction == 'buy' else 'triangle-down'),
                            name=f"MACD {conv.signal_direction}",
                            showlegend=False
                        ),
                        row=row, col=1
                    )
    
    def _add_volume_chart(self, fig, data: pd.DataFrame, row: int):
        """Add volume chart."""
        fig.add_trace(
            go.Bar(
                x=data.index,
                y=data['volume'],
                name='Volume',
                marker_color='lightblue',
                opacity=0.7
            ),
            row=row, col=1
        )
    
    def _calculate_rsi(self, prices: pd.Series, period: int = 14) -> pd.Series:
        """Calculate RSI."""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        return 100 - (100 / (1 + rs))
    
    def _calculate_macd(self, prices: pd.Series, fast: int = 12, slow: int = 26, signal: int = 9) -> Dict:
        """Calculate MACD."""
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
    
    def save_chart(self, fig, filename: str = "forex_analysis.html"):
        """Save chart to HTML file."""
        fig.write_html(f"reports/{filename}")
        print(f"Chart saved to reports/{filename}")
    
    def show_chart(self, fig):
        """Display chart in browser."""
        fig.show()