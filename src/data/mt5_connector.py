"""
MetaTrader 5 connector for live forex data.
"""
import MetaTrader5 as mt5
import pandas as pd
from datetime import datetime, timedelta
from typing import Optional, List, Dict
import time


class MT5Connector:
    """Connect to MT5 and fetch live forex data."""
    
    def __init__(self):
        self.connected = False
        self.account_info = None
    
    def connect(self, login: Optional[int] = None, password: Optional[str] = None, 
                server: Optional[str] = None) -> bool:
        """
        Connect to MT5 terminal.
        
        Args:
            login: MT5 account number (optional if already logged in)
            password: MT5 account password (optional)
            server: MT5 server name (optional)
        
        Returns:
            bool: True if connected successfully
        """
        # Initialize MT5
        if not mt5.initialize():
            print(f"❌ MT5 initialization failed: {mt5.last_error()}")
            return False
        
        # Login if credentials provided
        if login and password and server:
            if not mt5.login(login, password, server):
                print(f"❌ MT5 login failed: {mt5.last_error()}")
                mt5.shutdown()
                return False
            print(f"✅ Logged in to account #{login}")
        
        # Get account info
        self.account_info = mt5.account_info()
        if self.account_info is None:
            print(f"❌ Failed to get account info: {mt5.last_error()}")
            mt5.shutdown()
            return False
        
        self.connected = True
        self._print_account_info()
        return True
    
    def _print_account_info(self):
        """Print MT5 account information."""
        if self.account_info:
            print(f"\n{'='*60}")
            print(f"MT5 ACCOUNT INFORMATION")
            print(f"{'='*60}")
            print(f"Account: {self.account_info.login}")
            print(f"Server: {self.account_info.server}")
            print(f"Balance: ${self.account_info.balance:.2f}")
            print(f"Equity: ${self.account_info.equity:.2f}")
            print(f"Leverage: 1:{self.account_info.leverage}")
            print(f"Currency: {self.account_info.currency}")
            print(f"Company: {self.account_info.company}")
            print(f"{'='*60}\n")
    
    def get_live_data(self, symbol: str, timeframe: str, bars: int = 500) -> Optional[pd.DataFrame]:
        """
        Get live OHLC data from MT5.
        
        Args:
            symbol: Currency pair (e.g., "EURUSD")
            timeframe: Timeframe (M1, M5, M15, H1, H4, D1)
            bars: Number of bars to fetch
        
        Returns:
            DataFrame with OHLC data
        """
        if not self.connected:
            print("❌ Not connected to MT5. Call connect() first.")
            return None
        
        # Map timeframe string to MT5 constant
        timeframe_map = {
            'M1': mt5.TIMEFRAME_M1,
            'M5': mt5.TIMEFRAME_M5,
            'M15': mt5.TIMEFRAME_M15,
            'M30': mt5.TIMEFRAME_M30,
            'H1': mt5.TIMEFRAME_H1,
            'H4': mt5.TIMEFRAME_H4,
            'D1': mt5.TIMEFRAME_D1,
            'W1': mt5.TIMEFRAME_W1,
            'MN1': mt5.TIMEFRAME_MN1
        }
        
        mt5_timeframe = timeframe_map.get(timeframe.upper())
        if mt5_timeframe is None:
            print(f"❌ Invalid timeframe: {timeframe}")
            return None
        
        # Get rates
        rates = mt5.copy_rates_from_pos(symbol, mt5_timeframe, 0, bars)
        
        if rates is None or len(rates) == 0:
            print(f"❌ Failed to get data for {symbol}: {mt5.last_error()}")
            return None
        
        # Convert to DataFrame
        df = pd.DataFrame(rates)
        df['timestamp'] = pd.to_datetime(df['time'], unit='s')
        df = df[['timestamp', 'open', 'high', 'low', 'close', 'tick_volume']]
        df.rename(columns={'tick_volume': 'volume'}, inplace=True)
        
        print(f"✅ Fetched {len(df)} bars for {symbol} ({timeframe})")
        return df
    
    def get_symbol_info(self, symbol: str) -> Optional[Dict]:
        """Get symbol information."""
        if not self.connected:
            return None
        
        info = mt5.symbol_info(symbol)
        if info is None:
            print(f"❌ Symbol {symbol} not found")
            return None
        
        return {
            'symbol': info.name,
            'description': info.description,
            'point': info.point,
            'digits': info.digits,
            'spread': info.spread,
            'trade_contract_size': info.trade_contract_size,
            'currency_base': info.currency_base,
            'currency_profit': info.currency_profit,
            'bid': info.bid,
            'ask': info.ask
        }
    
    def get_available_symbols(self) -> List[str]:
        """Get list of available symbols."""
        if not self.connected:
            return []
        
        symbols = mt5.symbols_get()
        if symbols is None:
            return []
        
        # Filter for forex pairs
        forex_symbols = [s.name for s in symbols if 'USD' in s.name or 'EUR' in s.name or 'GBP' in s.name]
        return sorted(forex_symbols)[:50]  # Return first 50
    
    def get_current_price(self, symbol: str) -> Optional[Dict]:
        """Get current bid/ask price."""
        if not self.connected:
            return None
        
        tick = mt5.symbol_info_tick(symbol)
        if tick is None:
            return None
        
        return {
            'symbol': symbol,
            'bid': tick.bid,
            'ask': tick.ask,
            'spread': tick.ask - tick.bid,
            'time': datetime.fromtimestamp(tick.time)
        }
    
    def stream_live_data(self, symbol: str, timeframe: str, callback, interval: int = 60):
        """
        Stream live data continuously.
        
        Args:
            symbol: Currency pair
            timeframe: Timeframe
            callback: Function to call with new data
            interval: Update interval in seconds
        """
        print(f"🔄 Starting live data stream for {symbol} ({timeframe})")
        print(f"   Updates every {interval} seconds. Press Ctrl+C to stop.")
        
        try:
            while True:
                data = self.get_live_data(symbol, timeframe, bars=200)
                if data is not None:
                    callback(data, symbol, timeframe)
                
                time.sleep(interval)
        
        except KeyboardInterrupt:
            print("\n⏹️ Live stream stopped by user")
    
    def disconnect(self):
        """Disconnect from MT5."""
        if self.connected:
            mt5.shutdown()
            self.connected = False
            print("✅ Disconnected from MT5")
    
    def __del__(self):
        """Cleanup on deletion."""
        self.disconnect()


def test_connection():
    """Test MT5 connection."""
    connector = MT5Connector()
    
    print("Testing MT5 Connection...")
    print("Make sure MetaTrader 5 is running!\n")
    
    if connector.connect():
        print("✅ Connection successful!")
        
        # Test getting data
        print("\nTesting data fetch for EURUSD...")
        data = connector.get_live_data("EURUSD", "H1", bars=100)
        
        if data is not None:
            print(f"✅ Successfully fetched {len(data)} bars")
            print(f"\nLatest price data:")
            print(data.tail())
        
        # Get current price
        price = connector.get_current_price("EURUSD")
        if price:
            print(f"\n💹 Current EURUSD Price:")
            print(f"   Bid: {price['bid']:.5f}")
            print(f"   Ask: {price['ask']:.5f}")
            print(f"   Spread: {price['spread']:.5f}")
        
        connector.disconnect()
    else:
        print("❌ Connection failed!")
        print("\nTroubleshooting:")
        print("1. Make sure MetaTrader 5 is installed and running")
        print("2. Enable 'Algo Trading' in MT5 (Tools > Options > Expert Advisors)")
        print("3. Make sure you're logged into a demo/live account")


if __name__ == "__main__":
    test_connection()