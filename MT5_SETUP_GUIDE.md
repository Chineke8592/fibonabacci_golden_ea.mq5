# 🚀 MT5 Live Analysis Setup Guide

## 📋 Prerequisites

### 1. Install MetaTrader 5
- Download from: https://www.metatrader5.com/en/download
- Install the Windows version
- Create a **demo account** (or use your live account)

### 2. Python Environment
- Python 3.9+ installed
- Virtual environment set up (done automatically by batch file)

---

## 🔧 Step-by-Step Setup

### Step 1: Install MetaTrader 5

1. **Download MT5**
   - Go to https://www.metatrader5.com/en/download
   - Click "Download MetaTrader 5"
   - Run the installer

2. **Create Demo Account**
   - Open MT5
   - Click "File" → "Open an Account"
   - Select a broker (e.g., MetaQuotes-Demo)
   - Choose "Open a demo account"
   - Fill in your details
   - Save your login credentials!

3. **Enable Algo Trading**
   - In MT5, go to "Tools" → "Options"
   - Click "Expert Advisors" tab
   - ✅ Check "Allow automated trading"
   - ✅ Check "Allow DLL imports"
   - Click "OK"

### Step 2: Install Python Package

Open Command Prompt in your project folder and run:

```bash
forex_env\Scripts\activate
pip install MetaTrader5
```

Or simply run: `run_live_mt5.bat`

### Step 3: Test Connection

Run the test script:

```bash
python src/data/mt5_connector.py
```

You should see:
```
✅ Connection successful!
MT5 ACCOUNT INFORMATION
Account: 12345678
Server: MetaQuotes-Demo
Balance: $10000.00
...
```

---

## 🎯 Running Live Analysis

### Option 1: Quick Start (Recommended)

**Double-click:** `run_live_mt5.bat`

This will:
1. Activate virtual environment
2. Install/update MT5 package
3. Start the live analysis system

### Option 2: Manual Start

```bash
# Activate environment
forex_env\Scripts\activate

# Run live analysis
python src/live_mt5_analysis.py
```

---

## 📊 Usage Modes

### Mode 1: Single Analysis
Analyze a pair once and exit.

```
SELECT MODE:
1. Single Analysis (analyze once)

Enter choice: 1
Enter symbol: EURUSD
Enter timeframe: H1
```

**Output:**
- Elliott Wave counts
- Trend analysis
- Chart patterns
- 20-30 pip movements
- Trading recommendation

### Mode 2: Live Monitoring (Recommended)
Continuous analysis with auto-updates.

```
SELECT MODE:
2. Live Monitoring (continuous updates)

Enter choice: 2
Enter symbols: EURUSD,GBPUSD,USDJPY
Enter timeframe: H1
Enter update interval: 300
```

**Features:**
- Analyzes multiple pairs
- Updates every 5 minutes (300 seconds)
- Real-time price data
- Continuous wave counting
- Live trading signals

### Mode 3: Custom Analysis
Analyze any symbol with custom settings.

```
SELECT MODE:
3. Custom Symbol Analysis

Enter choice: 3
Enter symbol: XAUUSD
Enter timeframe: M15
Enter bars: 500
```

---

## 📈 What You'll See

### Live Analysis Output:

```
======================================================================
📊 LIVE ANALYSIS: EURUSD - H1
======================================================================
⏰ Time: 2025-11-04 15:30:00
💹 Current Price: Bid 1.09850 | Ask 1.09852
   Spread: 0.00002
📈 Analyzing 200 bars...

🔵 Elliott Wave Count:
   Total Waves: 12
   Impulse (1-5): 0
   Corrective (A-C): 12
   
   Latest Waves:
   • Wave A (correction): down 1.10344 → 1.09054 (1.17%)
   • Wave B (correction): up 1.09054 → 1.10057 (0.92%)
   • Wave A (correction): down 1.09565 → 1.08959 (0.55%)

📈 Trend Analysis:
   Current Trend: DOWNTREND (weak)
   Price: 1.10133 → 1.09318
   Change: -0.74%
   R²: 0.871

🎯 Chart Patterns:
   Found 10 patterns
   • double_top: Confidence 0.90
     Target: 1.07764

📍 Pip Movement Analysis (20-30 pips):
   Found 172 movements
   • UP: 28.2 pips (1.10000 → 1.10282)
   • UP: 22.3 pips (1.10060 → 1.10282)

💡 Trading Recommendation:
   ➡️ NEUTRAL - Wait for clearer signals
   ⏳ Recommendation: Stay on sidelines
   💹 Current: 1.09850
======================================================================
```

---

## ⚙️ Configuration

### Adjust Analysis Settings

Edit `config/pairs.json`:

```json
{
  "major_pairs": ["EURUSD", "GBPUSD", "USDJPY"],
  "analysis_settings": {
    "pip_intervals": {
      "min_pips": 20,
      "max_pips": 30
    },
    "timeframes": ["M15", "H1", "H4"]
  }
}
```

### Change Update Frequency

In live monitoring mode, adjust the interval:
- **60 seconds** = 1 minute (very frequent)
- **300 seconds** = 5 minutes (recommended)
- **900 seconds** = 15 minutes (less frequent)
- **3600 seconds** = 1 hour (long-term)

---

## 🔍 Available Timeframes

- **M1** - 1 minute
- **M5** - 5 minutes
- **M15** - 15 minutes
- **M30** - 30 minutes
- **H1** - 1 hour (recommended)
- **H4** - 4 hours
- **D1** - Daily
- **W1** - Weekly
- **MN1** - Monthly

---

## 💡 Trading Signals Explained

### Bullish Signals 📈
- Upward Elliott Waves (1, 3, 5)
- Uptrend detected
- Bullish chart patterns (double bottom, ascending triangle)
- **Action:** Consider long positions

### Bearish Signals 📉
- Downward Elliott Waves
- Downtrend detected
- Bearish chart patterns (double top, descending triangle)
- **Action:** Consider short positions

### Neutral ➡️
- Mixed signals
- Corrective wave phase
- Sideways trend
- **Action:** Wait for clearer setup

---

## 🛠️ Troubleshooting

### Problem: "MT5 initialization failed"

**Solutions:**
1. Make sure MT5 is **running**
2. Login to your account in MT5
3. Check if MT5 is not frozen/crashed
4. Restart MT5 and try again

### Problem: "Failed to get data for EURUSD"

**Solutions:**
1. Check if symbol name is correct (use MT5's symbol name)
2. Make sure you're connected to the internet
3. Verify the symbol is available in your MT5 account
4. Try a different symbol (e.g., GBPUSD)

### Problem: "Allow automated trading"

**Solutions:**
1. Open MT5
2. Tools → Options → Expert Advisors
3. ✅ Enable "Allow automated trading"
4. ✅ Enable "Allow DLL imports"
5. Click OK and restart the script

### Problem: "Symbol not found"

**Solutions:**
1. In MT5, right-click on "Market Watch"
2. Select "Show All"
3. Find your symbol and make it visible
4. Try the analysis again

---

## 📱 Monitoring Multiple Pairs

### Recommended Setup:

**For Day Trading:**
```
Symbols: EURUSD, GBPUSD, USDJPY
Timeframe: M15 or H1
Interval: 300 seconds (5 minutes)
```

**For Swing Trading:**
```
Symbols: EURUSD, GBPUSD, AUDUSD, USDCAD
Timeframe: H4 or D1
Interval: 3600 seconds (1 hour)
```

**For Scalping:**
```
Symbols: EURUSD (focus on one)
Timeframe: M1 or M5
Interval: 60 seconds (1 minute)
```

---

## 🎯 Best Practices

1. **Start with Demo Account**
   - Test the system thoroughly
   - Understand the signals
   - Practice risk management

2. **Monitor During Active Hours**
   - London session: 08:00-17:00 GMT
   - New York session: 13:00-22:00 GMT
   - Overlap: 13:00-17:00 GMT (most volatile)

3. **Use Multiple Timeframes**
   - Higher timeframe for trend direction
   - Lower timeframe for entry timing
   - Confirm signals across timeframes

4. **Combine with Other Analysis**
   - Support/resistance levels
   - Fundamental analysis
   - News events
   - Risk management

5. **Keep MT5 Running**
   - Don't close MT5 during analysis
   - Stable internet connection
   - Sufficient system resources

---

## 📊 Sample Trading Workflow

1. **Start Live Monitoring**
   ```bash
   run_live_mt5.bat
   Choose Mode 2 (Live Monitoring)
   ```

2. **Monitor Multiple Pairs**
   - System analyzes EURUSD, GBPUSD, USDJPY
   - Updates every 5 minutes
   - Shows Elliott Waves, trends, patterns

3. **Wait for Signal**
   - Look for "BULLISH BIAS" or "BEARISH BIAS"
   - Check wave count (impulse wave starting?)
   - Confirm with trend direction

4. **Plan Entry**
   - Use 20-30 pip analysis for entry point
   - Wait for pullback in impulse wave
   - Enter after Wave 2 completes

5. **Set Targets**
   - Target: Wave 3 extension
   - Stop loss: Below Wave 1
   - Risk/reward: Minimum 1:2

---

## 🔐 Security Notes

- **Never share your MT5 login credentials**
- Use demo account for testing
- The system only **reads** data, doesn't place trades
- No sensitive data is stored or transmitted

---

## 📞 Support

If you encounter issues:

1. Check MT5 is running and logged in
2. Verify "Allow automated trading" is enabled
3. Test connection: `python src/data/mt5_connector.py`
4. Check error messages carefully
5. Restart MT5 and try again

---

## 🎓 Learning Resources

- **Elliott Wave Theory**: https://www.investopedia.com/terms/e/elliottwavetheory.asp
- **MT5 Documentation**: https://www.mql5.com/en/docs
- **Forex Trading**: https://www.babypips.com/learn/forex

---

**Ready to start? Run:** `run_live_mt5.bat`

**Happy Trading! 📈💰**
