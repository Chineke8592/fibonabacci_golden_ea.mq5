"""
Live MT5 forex analysis with Elliott Wave counting.
"""
import json
import sys
from datetime import datetime
from data.mt5_connector import MT5Connector
from analyzers.multi_timeframe_analyzer import MultiTimeframeAnalyzer
from indicators.wave_counter import WaveCounter
from indicators.trend_analysis import TrendAnalyzer
from indicators.chart_patterns import ChartPatternRecognizer


class LiveForexAnalyzer:
    """Live forex analysis using MT5 data."""
    
    def __init__(self, config_path: str = 'config/pairs.json'):
        self.connector = MT5Connector()
        self.config = self._load_config(config_path)
        
        # Initialize analyzers
        self.wave_counter = WaveCounter(sensitivity=5)
        self.trend_analyzer = TrendAnalyzer()
        self.pattern_recognizer = ChartPatternRecognizer()
    
    def _load_config(self, path: str):
        """Load configuration."""
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️ Could not load config: {e}")
            return {
                'major_pairs': ['EURUSD', 'GBPUSD', 'USDJPY'],
                'analysis_settings': {
                    'pip_intervals': {'min_pips': 20, 'max_pips': 30},
                    'timeframes': ['M15', 'H1', 'H4']
                }
            }
    
    def connect_mt5(self, login: int = None, password: str = None, server: str = None):
        """Connect to MT5 terminal."""
        print("🔌 Connecting to MetaTrader 5...")
        
        if not self.connector.connect(login, password, server):
            print("\n❌ Failed to connect to MT5!")
            print("\n📋 Setup Instructions:")
            print("1. Install MetaTrader 5 from https://www.metatrader5.com")
            print("2. Open MT5 and login to your demo account")
            print("3. Go to Tools > Options > Expert Advisors")
            print("4. Enable 'Allow automated trading'")
            print("5. Run this script again")
            return False
        
        return True
    
    def analyze_pair(self, symbol: str, timeframe: str = 'H1', bars: int = 200):
        """Analyze a single currency pair."""
        print(f"\n{'='*70}")
        print(f"📊 LIVE ANALYSIS: {symbol} - {timeframe}")
        print(f"{'='*70}")
        print(f"⏰ Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Get live data from MT5
        data = self.connector.get_live_data(symbol, timeframe, bars)
        
        if data is None:
            print(f"❌ Could not fetch data for {symbol}")
            return
        
        # Get current price
        current_price = self.connector.get_current_price(symbol)
        if current_price:
            print(f"💹 Current Price: Bid {current_price['bid']:.5f} | Ask {current_price['ask']:.5f}")
            print(f"   Spread: {current_price['spread']:.5f}")
        
        print(f"📈 Analyzing {len(data)} bars...")
        
        # Run Elliott Wave counting
        print("\n🔵 Elliott Wave Count:")
        wave_counts = self.wave_counter.identify_wave_counts(data)
        
        if wave_counts:
            summary = self.wave_counter.get_wave_summary(wave_counts)
            print(f"   Total Waves: {summary['total_waves']}")
            print(f"   Impulse (1-5): {summary['impulse_count']}")
            print(f"   Corrective (A-C): {summary['corrective_count']}")
            
            # Show latest waves
            if wave_counts:
                print(f"\n   Latest Waves:")
                for wave in wave_counts[-3:]:
                    print(f"   • Wave {wave.wave_number} ({wave.wave_type}): {wave.direction} "
                          f"{wave.start_price:.5f} → {wave.end_price:.5f} ({wave.length_percent:.2f}%)")
        else:
            print("   No clear wave patterns detected yet")
        
        # Run trend analysis
        print("\n📈 Trend Analysis:")
        trends = self.trend_analyzer.identify_trends(data)
        
        if trends:
            latest_trend = trends[-1]
            print(f"   Current Trend: {latest_trend.direction.value.upper()} ({latest_trend.strength.value})")
            print(f"   Price: {latest_trend.start_price:.5f} → {latest_trend.end_price:.5f}")
            print(f"   Change: {latest_trend.percentage_change:+.2f}%")
            print(f"   R²: {latest_trend.r_squared:.3f}")
        
        # Run chart pattern recognition
        print("\n🎯 Chart Patterns:")
        patterns = self.pattern_recognizer.find_all_patterns(data)
        
        if patterns:
            print(f"   Found {len(patterns)} patterns")
            for pattern in patterns[:3]:
                print(f"   • {pattern.pattern_type.value}: Confidence {pattern.confidence:.2f}")
                if pattern.target_price:
                    print(f"     Target: {pattern.target_price:.5f}")
        else:
            print("   No patterns detected")
        
        # Pip analysis
        print("\n📍 Pip Movement Analysis (20-30 pips):")
        pip_analyzer = MultiTimeframeAnalyzer(symbol, pip_intervals=(20, 30))
        pip_movements = pip_analyzer.analyze_timeframe(data, timeframe)
        
        if pip_movements:
            print(f"   Found {len(pip_movements)} movements")
            for mov in pip_movements[-5:]:
                print(f"   • {mov.direction.upper()}: {mov.pip_change:.1f} pips "
                      f"({mov.start_price:.5f} → {mov.end_price:.5f})")
        
        # Trading recommendation
        self._print_trading_recommendation(wave_counts, trends, patterns, current_price)
        
        print(f"\n{'='*70}\n")
    
    def _print_trading_recommendation(self, waves, trends, patterns, current_price):
        """Print trading recommendation based on analysis."""
        print("\n💡 Trading Recommendation:")
        
        bullish_signals = 0
        bearish_signals = 0
        
        # Count signals
        if waves:
            for wave in waves[-5:]:
                if wave.direction == 'up':
                    bullish_signals += 1
                else:
                    bearish_signals += 1
        
        if trends:
            latest_trend = trends[-1]
            if latest_trend.direction.value == 'uptrend':
                bullish_signals += 2
            elif latest_trend.direction.value == 'downtrend':
                bearish_signals += 2
        
        # Recommendation
        if bullish_signals > bearish_signals + 2:
            print("   📈 BULLISH BIAS - Consider long positions")
            print("   ✅ Entry: Wait for pullback to support")
            print("   🎯 Target: Next resistance level")
        elif bearish_signals > bullish_signals + 2:
            print("   📉 BEARISH BIAS - Consider short positions")
            print("   ✅ Entry: Wait for bounce to resistance")
            print("   🎯 Target: Next support level")
        else:
            print("   ➡️ NEUTRAL - Wait for clearer signals")
            print("   ⏳ Recommendation: Stay on sidelines")
        
        if current_price:
            print(f"   💹 Current: {current_price['bid']:.5f}")
    
    def run_live_monitoring(self, symbols: list = None, timeframe: str = 'H1', 
                           interval: int = 300):
        """
        Run continuous live monitoring.
        
        Args:
            symbols: List of symbols to monitor (default: from config)
            timeframe: Timeframe to analyze
            interval: Update interval in seconds (default: 5 minutes)
        """
        if symbols is None:
            symbols = self.config.get('major_pairs', ['EURUSD'])[:3]
        
        print(f"\n{'='*70}")
        print(f"🔴 LIVE MONITORING STARTED")
        print(f"{'='*70}")
        print(f"Symbols: {', '.join(symbols)}")
        print(f"Timeframe: {timeframe}")
        print(f"Update Interval: {interval} seconds ({interval//60} minutes)")
        print(f"Press Ctrl+C to stop")
        print(f"{'='*70}\n")
        
        try:
            cycle = 1
            while True:
                print(f"\n🔄 Analysis Cycle #{cycle} - {datetime.now().strftime('%H:%M:%S')}")
                
                for symbol in symbols:
                    try:
                        self.analyze_pair(symbol, timeframe)
                    except Exception as e:
                        print(f"❌ Error analyzing {symbol}: {e}")
                
                print(f"\n⏳ Next update in {interval} seconds...")
                print(f"{'='*70}")
                
                import time
                time.sleep(interval)
                cycle += 1
        
        except KeyboardInterrupt:
            print("\n\n⏹️ Live monitoring stopped by user")
    
    def disconnect(self):
        """Disconnect from MT5."""
        self.connector.disconnect()


def main():
    """Main entry point for live MT5 analysis."""
    print("="*70)
    print("🚀 LIVE MT5 FOREX ANALYSIS SYSTEM")
    print("="*70)
    print("Features: Elliott Wave • Trends • Patterns • Pip Analysis")
    print("="*70)
    
    analyzer = LiveForexAnalyzer()
    
    # Connect to MT5
    if not analyzer.connect_mt5():
        return
    
    # Get available symbols
    print("\n📋 Available symbols:")
    symbols = analyzer.connector.get_available_symbols()
    if symbols:
        print(f"   Found {len(symbols)} forex pairs")
        print(f"   Examples: {', '.join(symbols[:10])}")
    
    # Menu
    print("\n" + "="*70)
    print("SELECT MODE:")
    print("="*70)
    print("1. Single Analysis (analyze once)")
    print("2. Live Monitoring (continuous updates)")
    print("3. Custom Symbol Analysis")
    print("="*70)
    
    try:
        choice = input("\nEnter choice (1-3): ").strip()
        
        if choice == '1':
            # Single analysis
            symbol = input("Enter symbol (default: EURUSD): ").strip().upper() or "EURUSD"
            timeframe = input("Enter timeframe (M15/H1/H4, default: H1): ").strip().upper() or "H1"
            analyzer.analyze_pair(symbol, timeframe)
        
        elif choice == '2':
            # Live monitoring
            symbols_input = input("Enter symbols separated by comma (default: EURUSD,GBPUSD,USDJPY): ").strip().upper()
            symbols = [s.strip() for s in symbols_input.split(',')] if symbols_input else ['EURUSD', 'GBPUSD', 'USDJPY']
            
            timeframe = input("Enter timeframe (default: H1): ").strip().upper() or "H1"
            interval = input("Enter update interval in seconds (default: 300): ").strip()
            interval = int(interval) if interval.isdigit() else 300
            
            analyzer.run_live_monitoring(symbols, timeframe, interval)
        
        elif choice == '3':
            # Custom analysis
            symbol = input("Enter symbol: ").strip().upper()
            timeframe = input("Enter timeframe: ").strip().upper()
            bars = input("Enter number of bars (default: 200): ").strip()
            bars = int(bars) if bars.isdigit() else 200
            
            analyzer.analyze_pair(symbol, timeframe, bars)
        
        else:
            print("Invalid choice!")
    
    except KeyboardInterrupt:
        print("\n\n⏹️ Stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
    finally:
        analyzer.disconnect()
        print("\n✅ Analysis complete!")


if __name__ == "__main__":
    main()