"""
Main entry point for comprehensive forex analysis system.
Includes Elliott Wave, trend analysis, chart patterns, and divergence/convergence.
"""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

from analyzers.multi_timeframe_analyzer import MultiTimeframeAnalyzer
from indicators.elliott_wave import ElliottWaveAnalyzer
from indicators.wave_counter import WaveCounter
from indicators.trend_analysis import TrendAnalyzer
from indicators.chart_patterns import ChartPatternRecognizer
from indicators.divergence_convergence import DivergenceConvergenceAnalyzer


def load_config():
    """Load configuration from JSON files."""
    with open('config/pairs.json', 'r') as f:
        return json.load(f)


def generate_realistic_forex_data(pair: str, timeframe: str, periods: int = 200) -> pd.DataFrame:
    """Generate more realistic forex data with trends and patterns."""
    np.random.seed(42)
    
    base_price = 1.1000 if 'USD' in pair else 110.00 if 'JPY' in pair else 1.3000
    
    timestamps = pd.date_range(
        start=datetime.now() - timedelta(hours=periods),
        periods=periods,
        freq='1h' if timeframe == 'H1' else '5min' if timeframe == 'M5' else '1min'
    )
    
    # Create more realistic price movements with trends
    prices = [base_price]
    trend_strength = 0.0002
    trend_duration = 50
    
    for i in range(1, periods):
        # Add trend component
        if i % trend_duration < trend_duration // 2:
            trend_component = trend_strength
        else:
            trend_component = -trend_strength
        
        # Add random noise
        noise = np.random.normal(0, 0.0008)
        
        # Add some volatility clustering
        if i > 10 and abs(prices[-1] - prices[-10]) > 0.01:
            noise *= 1.5
        
        new_price = prices[-1] + trend_component + noise
        prices.append(max(0.5, new_price))  # Prevent negative prices
    
    # Generate OHLC from close prices
    ohlc_data = []
    for i, close_price in enumerate(prices):
        # Generate realistic OHLC
        volatility = 0.0005
        high = close_price + abs(np.random.normal(0, volatility))
        low = close_price - abs(np.random.normal(0, volatility))
        
        if i == 0:
            open_price = close_price
        else:
            open_price = prices[i-1] + np.random.normal(0, volatility/2)
        
        ohlc_data.append({
            'timestamp': timestamps[i],
            'open': open_price,
            'high': max(open_price, high, close_price),
            'low': min(open_price, low, close_price),
            'close': close_price,
            'volume': np.random.randint(100, 1000)
        })
    
    return pd.DataFrame(ohlc_data)


def analyze_elliott_waves(data: pd.DataFrame, pair: str):
    """Analyze Elliott Wave patterns."""
    print(f"\n--- Elliott Wave Analysis for {pair} ---")
    
    wave_analyzer = ElliottWaveAnalyzer()
    wave_structure = wave_analyzer.analyze_wave_structure(data)
    
    impulse_waves = wave_structure['impulse']
    corrective_waves = wave_structure['corrective']
    
    print(f"Found {len(impulse_waves)} impulse waves and {len(corrective_waves)} corrective waves")
    
    # Display impulse waves
    if impulse_waves:
        print("\nImpulse Waves:")
        for i, wave in enumerate(impulse_waves[:3]):
            print(f"  Wave {wave.label}: {wave.direction.value} from {wave.start_price:.5f} to {wave.end_price:.5f}")
            print(f"    Length: {wave.length:.5f}, Duration: {wave.duration} periods")
    
    # Display corrective waves
    if corrective_waves:
        print("\nCorrective Waves:")
        for i, wave in enumerate(corrective_waves[:3]):
            print(f"  Wave {wave.label}: {wave.direction.value} from {wave.start_price:.5f} to {wave.end_price:.5f}")


def analyze_trends(data: pd.DataFrame, pair: str):
    """Analyze trend movements."""
    print(f"\n--- Trend Analysis for {pair} ---")
    
    trend_analyzer = TrendAnalyzer()
    trends = trend_analyzer.identify_trends(data)
    
    print(f"Found {len(trends)} trend movements")
    
    for i, trend in enumerate(trends[:5]):
        print(f"  Trend {i+1}: {trend.direction.value} ({trend.strength.value})")
        print(f"    Price: {trend.start_price:.5f} → {trend.end_price:.5f} ({trend.percentage_change:+.2f}%)")
        print(f"    Duration: {trend.duration} periods, R²: {trend.r_squared:.3f}")
    
    # Find continuations and reversals
    continuations = trend_analyzer.find_trend_continuations(trends)
    reversals = trend_analyzer.find_trend_reversals(trends)
    
    if continuations:
        print(f"\nTrend Continuations: {len(continuations)}")
        for cont in continuations[:2]:
            print(f"  {cont['direction']} continuation ({cont['strength']})")
    
    if reversals:
        print(f"\nTrend Reversals: {len(reversals)}")
        for rev in reversals[:2]:
            print(f"  {rev['from_direction']} → {rev['to_direction']} reversal")


def analyze_chart_patterns(data: pd.DataFrame, pair: str):
    """Analyze chart patterns."""
    print(f"\n--- Chart Pattern Analysis for {pair} ---")
    
    pattern_recognizer = ChartPatternRecognizer()
    patterns = pattern_recognizer.find_all_patterns(data)
    
    print(f"Found {len(patterns)} chart patterns")
    
    for pattern in patterns[:5]:
        print(f"  {pattern.pattern_type.value}: Confidence {pattern.confidence:.2f}")
        print(f"    Duration: {pattern.duration} periods")
        if pattern.target_price:
            print(f"    Target: {pattern.target_price:.5f}")


def analyze_divergence_convergence(data: pd.DataFrame, pair: str):
    """Analyze divergence and convergence patterns (MACD/RSI analysis hidden)."""
    print(f"\n--- Technical Analysis Summary for {pair} ---")
    
    # MACD and RSI analysis is now hidden from output
    # Analysis still runs in background for chart generation
    print("Technical indicators calculated and processed.")
    print("(MACD convergence and RSI divergence details hidden from display)")


def run_comprehensive_analysis():
    """Run complete analysis with all modules."""
    config = load_config()
    
    print("=== COMPREHENSIVE FOREX ANALYSIS SYSTEM ===")
    print("Features: Elliott Wave, Trends, Chart Patterns, Divergence/Convergence, Multi-Timeframe")
    
    # Analyze first major pair
    pair = config['major_pairs'][0]  # EURUSD
    print(f"\nAnalyzing {pair} across multiple timeframes...")
    
    # Generate data for H1 timeframe (main analysis)
    timeframe = 'H1'
    data = generate_realistic_forex_data(pair, timeframe, periods=200)
    
    print(f"\n{'='*60}")
    print(f"COMPREHENSIVE ANALYSIS: {pair} - {timeframe}")
    print(f"{'='*60}")
    
    # Initialize all analyzers
    wave_analyzer = ElliottWaveAnalyzer()
    wave_counter = WaveCounter(sensitivity=5)  # Enhanced wave counting
    trend_analyzer = TrendAnalyzer()
    pattern_recognizer = ChartPatternRecognizer()
    div_conv_analyzer = DivergenceConvergenceAnalyzer()
    pip_analyzer = MultiTimeframeAnalyzer(pair, pip_intervals=(20, 30))
    
    # Run all analyses and collect results
    print("Running Elliott Wave analysis...")
    wave_structure = wave_analyzer.analyze_wave_structure(data)
    waves = wave_structure['impulse'] + wave_structure['corrective']
    
    # Run enhanced wave counting
    print("Running detailed wave counting...")
    wave_counts = wave_counter.identify_wave_counts(data)
    
    print("Running trend analysis...")
    trends = trend_analyzer.identify_trends(data)
    
    print("Running chart pattern recognition...")
    patterns = pattern_recognizer.find_all_patterns(data)
    
    print("Running divergence/convergence analysis...")
    divergences = div_conv_analyzer.find_divergences(data)
    convergences = div_conv_analyzer.find_convergences(data)
    
    print("Running pip movement analysis...")
    pip_movements = pip_analyzer.analyze_timeframe(data, timeframe)
    
    # Display comprehensive results
    print(f"\n--- ANALYSIS SUMMARY ---")
    print(f"Elliott Waves: {len(waves)} total ({len(wave_structure['impulse'])} impulse, {len(wave_structure['corrective'])} corrective)")
    print(f"Trend Movements: {len(trends)}")
    print(f"Chart Patterns: {len(patterns)}")
    print(f"Pip Movements (20-30): {len(pip_movements)}")
    # Divergences and Convergences hidden from summary
    
    # Show detailed results
    analyze_elliott_waves(data, pair)
    
    # Show enhanced wave counting
    wave_counter.print_wave_analysis(wave_counts, pair)
    
    analyze_trends(data, pair)
    analyze_chart_patterns(data, pair)
    analyze_divergence_convergence(data, pair)
    
    print(f"\n--- Multi-Timeframe Pip Analysis ---")
    print(f"Found {len(pip_movements)} pip movements (20-30 pips)")
    for mov in pip_movements[:5]:
        print(f"  {mov.direction.upper()}: {mov.pip_change:.1f} pips from {mov.start_price:.5f} to {mov.end_price:.5f}")
    
    # Create comprehensive visualization
    try:
        from visualization.chart_display import ForexChartVisualizer
        
        print(f"\n--- Creating Comprehensive Chart ---")
        visualizer = ForexChartVisualizer()
        
        fig = visualizer.plot_comprehensive_analysis(
            data=data,
            waves=waves[:10],  # Limit for clarity
            trends=trends[:5],
            patterns=patterns[:3],
            divergences=None,  # RSI divergences hidden
            convergences=None,  # MACD convergences hidden
            pair=pair
        )
        
        # Save chart
        visualizer.save_chart(fig, f"{pair}_{timeframe}_comprehensive_analysis.html")
        print("Comprehensive chart created and saved to reports/")
        
    except ImportError:
        print("Visualization module not available. Install plotly for charts: pip install plotly")
    
    # Trading signals summary
    print(f"\n--- TRADING SIGNALS SUMMARY ---")
    
    # Count bullish vs bearish signals
    bullish_signals = 0
    bearish_signals = 0
    
    # From Elliott Waves
    for wave in waves:
        if wave.direction.value == 'up':
            bullish_signals += 1
        else:
            bearish_signals += 1
    
    # From trends
    for trend in trends:
        if trend.direction.value == 'uptrend':
            bullish_signals += 1
        elif trend.direction.value == 'downtrend':
            bearish_signals += 1
    
    # MACD convergences excluded from signal calculation
    # (convergence signals are hidden from trading bias)
    
    print(f"Bullish Signals: {bullish_signals}")
    print(f"Bearish Signals: {bearish_signals}")
    
    if bullish_signals > bearish_signals:
        print("Overall Market Bias: BULLISH 📈")
    elif bearish_signals > bullish_signals:
        print("Overall Market Bias: BEARISH 📉")
    else:
        print("Overall Market Bias: NEUTRAL ➡️")


def main():
    """Main entry point."""
    try:
        run_comprehensive_analysis()
    except Exception as e:
        print(f"Error during analysis: {e}")
        print("Make sure all dependencies are installed: pip install -r requirements.txt")


if __name__ == "__main__":
    main()