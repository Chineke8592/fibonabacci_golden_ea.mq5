# 🚀 Quick Start - MT5 Live Analysis

## ⚡ 5-Minute Setup

### Step 1: Install MetaTrader 5 (2 minutes)

1. Download MT5: https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
2. Run installer
3. Open MT5 → File → Open an Account → Demo Account
4. Save your login details

### Step 2: Enable Algo Trading (30 seconds)

In MT5:
- Tools → Options → Expert Advisors
- ✅ Check "Allow automated trading"
- ✅ Check "Allow DLL imports"
- Click OK

### Step 3: Install MT5 Python Package (1 minute)

Open Command Prompt in project folder:

```bash
forex_env\Scripts\activate
pip install MetaTrader5
```

**If that fails**, download manually:
1. Go to: https://pypi.org/project/MetaTrader5/#files
2. Download the `.whl` file for your Python version
3. Install: `pip install MetaTrader5-5.0.4518-py3-none-win_amd64.whl`

### Step 4: Run Live Analysis (30 seconds)

**Double-click:** `run_live_mt5.bat`

Or manually:
```bash
forex_env\Scripts\activate
python src/live_mt5_analysis.py
```

---

## 🎯 First Run

When you run the script, you'll see:

```
SELECT MODE:
1. Single Analysis (analyze once)
2. Live Monitoring (continuous updates)
3. Custom Symbol Analysis
```

### Recommended for First Time:

**Choose Option 1** (Single Analysis)

```
Enter choice: 1
Enter symbol: EURUSD
Enter timeframe: H1
```

You'll get:
- ✅ Elliott Wave count
- ✅ Trend analysis
- ✅ Chart patterns
- ✅ 20-30 pip movements
- ✅ Trading recommendation

---

## 📊 Live Monitoring (Recommended)

**Choose Option 2** for continuous analysis:

```
Enter choice: 2
Enter symbols: EURUSD,GBPUSD,USDJPY
Enter timeframe: H1
Enter update interval: 300
```

This will:
- Analyze 3 pairs every 5 minutes
- Show real-time Elliott Waves
- Give live trading signals
- Update automatically

**Press Ctrl+C to stop**

---

## 💡 What Each Mode Does

### Mode 1: Single Analysis
- Analyzes once and exits
- Good for quick checks
- Perfect for learning the system

### Mode 2: Live Monitoring ⭐ (Best)
- Continuous analysis
- Multiple pairs
- Auto-updates
- Real-time signals

### Mode 3: Custom Analysis
- Analyze any symbol
- Custom timeframe
- Custom number of bars

---

## 🎨 Sample Output

```
======================================================================
📊 LIVE ANALYSIS: EURUSD - H1
======================================================================
⏰ Time: 2025-11-04 15:30:00
💹 Current Price: Bid 1.09850 | Ask 1.09852

🔵 Elliott Wave Count:
   Total Waves: 12
   Impulse (1-5): 0
   Corrective (A-C): 12
   
   Latest Waves:
   • Wave A: down 1.10344 → 1.09054 (1.17%)
   • Wave B: up 1.09054 → 1.10057 (0.92%)

📈 Trend Analysis:
   Current Trend: DOWNTREND (weak)
   Change: -0.74%

🎯 Chart Patterns:
   • double_top: Confidence 0.90

📍 Pip Movements (20-30 pips):
   Found 172 movements
   • UP: 28.2 pips

💡 Trading Recommendation:
   ➡️ NEUTRAL - Wait for clearer signals
======================================================================
```

---

## ⚠️ Troubleshooting

### "MT5 initialization failed"
✅ **Solution:** Make sure MT5 is running and you're logged in

### "Failed to get data"
✅ **Solution:** Check symbol name (use exact MT5 symbol)

### "MetaTrader5 module not found"
✅ **Solution:** Run `pip install MetaTrader5`

### "Allow automated trading"
✅ **Solution:** Enable in MT5 Options → Expert Advisors

---

## 📱 Recommended Settings

### For Day Trading:
```
Symbols: EURUSD, GBPUSD
Timeframe: H1
Interval: 300 seconds (5 min)
```

### For Swing Trading:
```
Symbols: EURUSD, GBPUSD, USDJPY
Timeframe: H4
Interval: 3600 seconds (1 hour)
```

### For Scalping:
```
Symbols: EURUSD
Timeframe: M15
Interval: 60 seconds (1 min)
```

---

## 🎓 Understanding the Signals

### 📈 BULLISH BIAS
- **Meaning:** Upward momentum detected
- **Action:** Look for long entry
- **Entry:** Wait for pullback
- **Target:** Next resistance

### 📉 BEARISH BIAS
- **Meaning:** Downward momentum detected
- **Action:** Look for short entry
- **Entry:** Wait for bounce
- **Target:** Next support

### ➡️ NEUTRAL
- **Meaning:** No clear direction
- **Action:** Stay on sidelines
- **Wait:** For clearer setup

---

## 🔥 Pro Tips

1. **Keep MT5 Running**
   - Don't close MT5 during analysis
   - Stable internet connection required

2. **Start with Demo**
   - Test thoroughly before live trading
   - Understand the signals first

3. **Use Multiple Timeframes**
   - H4 for trend direction
   - H1 for entry timing
   - M15 for precise entries

4. **Monitor During Active Hours**
   - London: 08:00-17:00 GMT
   - New York: 13:00-22:00 GMT
   - Best: 13:00-17:00 GMT (overlap)

5. **Combine Analysis**
   - Elliott Waves for structure
   - Trends for direction
   - Patterns for confirmation
   - 20-30 pips for entry timing

---

## ✅ Checklist

Before running live analysis:

- [ ] MT5 installed and running
- [ ] Logged into demo account
- [ ] Algo trading enabled in MT5
- [ ] MetaTrader5 Python package installed
- [ ] Virtual environment activated
- [ ] Internet connection stable

---

## 🚀 Ready to Start?

**Run:** `run_live_mt5.bat`

**Or:**
```bash
forex_env\Scripts\activate
python src/live_mt5_analysis.py
```

---

**Need help?** Check `MT5_SETUP_GUIDE.md` for detailed instructions.

**Happy Trading! 📈💰**
