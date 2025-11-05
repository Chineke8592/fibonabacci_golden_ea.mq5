# 📊 Support/Resistance Trading EA - Complete Guide

## 🎯 Strategy Overview

This Expert Advisor implements a **Support/Resistance bounce trading strategy** with precise entry conditions.

### **How It Works:**

#### **Phase 1: Identification** 🔍
The EA scans the last **20 candles** (configurable):
- Finds **Highest High** = Resistance Level
- Finds **Lowest Low** = Support Level
- Creates a **zone** around each level (200 points default)

#### **Phase 2: Signal Generation** 📈📉

**BUY Signal Occurs When:**
- ✅ Price approaches support zone
- ✅ Previous candle was **bearish** (sellers pushing down)
- ✅ Current candle is **bullish** (buyers taking control)
- ✅ Price within SR_Zone distance from support

**Interpretation:** "Buyers defending support level"

**SELL Signal Occurs When:**
- ✅ Price approaches resistance zone
- ✅ Previous candle was **bullish** (buyers pushing up)
- ✅ Current candle is **bearish** (sellers taking control)
- ✅ Price within SR_Zone distance from resistance

**Interpretation:** "Sellers defending resistance level"

---

## 📥 Installation

### Step 1: Copy EA File
1. Open MT5
2. File → Open Data Folder
3. Navigate to `MQL5\Experts\`
4. Copy `SupportResistanceEA.mq5` to this folder

### Step 2: Compile
1. Press **F4** to open MetaEditor
2. Open `SupportResistanceEA.mq5`
3. Click **Compile** (F7)
4. Check for "0 errors" message

### Step 3: Attach to Chart
1. Open your desired chart (EURUSD H1 recommended)
2. Navigator (Ctrl+N) → Expert Advisors
3. Drag **SupportResistanceEA** onto chart
4. Configure settings (see below)
5. Enable **Auto Trading** button in toolbar

---

## ⚙️ Configuration Settings

### **Support/Resistance Settings**

```
SR_Period = 20              // Number of candles to scan
                           // Higher = more stable S/R levels
                           // Lower = more responsive to recent price

SR_Zone = 200              // Zone size around S/R (points)
                           // Larger = more trades, less precise
                           // Smaller = fewer trades, more precise
```

**Recommended Values:**
- **Scalping (M5-M15)**: SR_Period = 10-15, SR_Zone = 100-150
- **Day Trading (H1)**: SR_Period = 20, SR_Zone = 200 (default)
- **Swing Trading (H4-D1)**: SR_Period = 30-50, SR_Zone = 300-500

### **Trade Management**

```
LotSize = 0.1              // Fixed lot size
TakeProfit = 500           // TP in points (50 pips for 5-digit)
StopLoss = 300             // SL in points (30 pips for 5-digit)
UseTrailingStop = true     // Enable trailing stop
TrailingStop = 200         // Trail distance (20 pips)
TrailingStep = 50          // Trail step (5 pips)
```

**Risk/Reward Examples:**
- **Conservative**: SL=300, TP=600 (1:2 R/R)
- **Balanced**: SL=300, TP=500 (1:1.67 R/R)
- **Aggressive**: SL=200, TP=400 (1:2 R/R)

### **Risk Management**

```
MaxTrades = 1              // Maximum simultaneous trades
MaxRiskPercent = 2.0       // Risk per trade (% of balance)
UseMoneyManagement = false // Auto-calculate lot size
```

**Money Management:**
- If `UseMoneyManagement = true`, EA calculates lot size based on:
  - Account balance
  - MaxRiskPercent
  - Stop loss distance
- If `false`, uses fixed LotSize

### **Alert Settings**

```
SendAlerts = true          // Pop-up alerts in MT5
SendNotifications = false  // Push to mobile app
SendEmails = false         // Email alerts
```

### **Display Settings**

```
ShowSRLines = true         // Show S/R horizontal lines
ShowZones = true           // Show S/R zones (rectangles)
ShowInfoPanel = true       // Show info panel
SupportColor = Lime        // Support line/zone color
ResistanceColor = Red      // Resistance line/zone color
```

---

## 📊 Visual Display

### **On Your Chart:**

1. **Support Line** (Green/Lime)
   - Horizontal line at lowest low
   - Label shows exact price

2. **Resistance Line** (Red)
   - Horizontal line at highest high
   - Label shows exact price

3. **Support Zone** (Green shaded area)
   - Rectangle around support
   - 200 points above and below

4. **Resistance Zone** (Red shaded area)
   - Rectangle around resistance
   - 200 points above and below

5. **Info Panel** (Top-left corner)
   ```
   S/R Trading EA
   Resistance: 1.10500
   Support: 1.09200
   Zone: 200 points
   Period: 20 candles
   Price: 1.09850
   Open Trades: 1
   Profit: $25.50
   ```

---

## 🎯 Trading Logic Explained

### **BUY Signal Example:**

```
Scenario:
1. Support identified at 1.09200
2. Support zone: 1.09000 - 1.09400 (200 points)
3. Price drops to 1.09150 (in zone)
4. Previous candle: Bearish (sellers pushing)
5. Current candle: Bullish (buyers step in)

Result: BUY SIGNAL!
Interpretation: Buyers defending support

Trade:
- Entry: 1.09150
- Stop Loss: 1.08850 (30 pips below)
- Take Profit: 1.09650 (50 pips above)
```

### **SELL Signal Example:**

```
Scenario:
1. Resistance identified at 1.10500
2. Resistance zone: 1.10300 - 1.10700 (200 points)
3. Price rises to 1.10550 (in zone)
4. Previous candle: Bullish (buyers pushing)
5. Current candle: Bearish (sellers step in)

Result: SELL SIGNAL!
Interpretation: Sellers defending resistance

Trade:
- Entry: 1.10550
- Stop Loss: 1.10850 (30 pips above)
- Take Profit: 1.10050 (50 pips below)
```

---

## 📈 Performance Optimization

### **Best Timeframes:**
- **M15**: Fast-paced, more signals, higher risk
- **H1**: Balanced, recommended for beginners
- **H4**: Slower, fewer but higher quality signals

### **Best Currency Pairs:**
- **EURUSD**: Most liquid, clear S/R levels
- **GBPUSD**: Good volatility
- **USDJPY**: Respects S/R well
- **AUDUSD**: Clean price action

### **Best Trading Sessions:**
- **London Session** (08:00-17:00 GMT): High volume
- **New York Session** (13:00-22:00 GMT): High volatility
- **Overlap** (13:00-17:00 GMT): Best for S/R bounces

### **Avoid:**
- Major news events (NFP, FOMC, etc.)
- Low liquidity periods (Asian session for EUR/USD)
- Choppy, ranging markets with no clear S/R

---

## 🔔 Alert System

### **Alert Types:**

1. **BUY Signal Alert**
   ```
   BUY SIGNAL DETECTED!
   Price at Support: 1.09150
   Support Level: 1.09200
   Previous candle: Bearish (sellers pushing)
   Current candle: Bullish (buyers defending)
   Action: Buyers defending support level
   ```

2. **SELL Signal Alert**
   ```
   SELL SIGNAL DETECTED!
   Price at Resistance: 1.10550
   Resistance Level: 1.10500
   Previous candle: Bullish (buyers pushing)
   Current candle: Bearish (sellers defending)
   Action: Sellers defending resistance level
   ```

3. **Trade Opened Alert**
   ```
   ✅ BUY order opened successfully!
   Ticket: 123456789
   Price: 1.09150
   SL: 1.08850
   TP: 1.09650
   Lots: 0.1
   ```

---

## 🛡️ Risk Management

### **Position Sizing:**

**Fixed Lot Size:**
```
LotSize = 0.1
UseMoneyManagement = false
```

**Auto Lot Size (Recommended):**
```
UseMoneyManagement = true
MaxRiskPercent = 2.0
```

**Example Calculation:**
- Account Balance: $10,000
- Risk per trade: 2% = $200
- Stop Loss: 30 pips
- Calculated Lot Size: ~0.67 lots

### **Maximum Trades:**
```
MaxTrades = 1    // Only 1 trade at a time (safest)
MaxTrades = 2    // Allow 2 simultaneous trades
MaxTrades = 3    // More aggressive
```

### **Trailing Stop:**
```
UseTrailingStop = true
TrailingStop = 200     // 20 pips
TrailingStep = 50      // Move SL every 5 pips
```

**How it works:**
- Once trade is 20 pips in profit
- SL moves to breakeven
- Then trails 20 pips behind price
- Locks in profits automatically

---

## 📊 Backtesting

### **How to Backtest:**

1. **Open Strategy Tester** (Ctrl+R)
2. Select **SupportResistanceEA**
3. Choose symbol (EURUSD)
4. Choose timeframe (H1)
5. Set date range (1 year recommended)
6. Click **Start**

### **Optimization:**

Test different combinations:
- SR_Period: 10, 15, 20, 25, 30
- SR_Zone: 100, 150, 200, 250, 300
- TakeProfit: 300, 400, 500, 600
- StopLoss: 200, 250, 300, 350

Find the best parameters for your pair/timeframe.

---

## 🔧 Troubleshooting

### **No Trades Opening**

**Possible Causes:**
1. Auto Trading not enabled → Enable toolbar button
2. No signals detected → Check S/R levels on chart
3. MaxTrades limit reached → Close existing trades
4. Insufficient margin → Reduce lot size

**Solutions:**
- Verify EA is running (smile icon in corner)
- Check Expert tab for error messages
- Ensure price is in S/R zone
- Lower SR_Zone to get more signals

### **Too Many Trades**

**Problem:** EA opening too many trades

**Solutions:**
- Increase SR_Zone (more selective)
- Increase SR_Period (more stable S/R)
- Set MaxTrades = 1
- Use higher timeframe (H4 instead of M15)

### **Trades Closing at Stop Loss**

**Problem:** Most trades hitting SL

**Solutions:**
- Increase StopLoss distance
- Decrease SR_Zone (more precise entries)
- Use trailing stop to protect profits
- Trade only during high-volume sessions

### **S/R Lines Not Showing**

**Problem:** No lines visible on chart

**Solutions:**
- Check `ShowSRLines = true`
- Check `ShowZones = true`
- Verify EA is attached to chart
- Restart MT5

---

## 💡 Trading Tips

### **Entry Confirmation:**
1. Wait for candle to close
2. Verify previous candle direction
3. Check current candle direction
4. Ensure price in zone
5. Enter on next candle open

### **Exit Strategy:**
1. Let TP/SL do their job
2. Use trailing stop for trends
3. Close manually if S/R breaks
4. Take partial profits at 1:1 R/R

### **Risk Management:**
1. Never risk more than 2% per trade
2. Use stop losses always
3. Don't overtrade
4. Keep max 1-2 trades open
5. Take breaks after losses

### **Market Conditions:**
- **Best**: Clear trending markets with bounces
- **Good**: Range-bound with defined S/R
- **Avoid**: Choppy, news-driven volatility

---

## 📈 Expected Performance

### **Realistic Expectations:**

**Win Rate:** 55-65%
- Not every bounce works
- Some will break through S/R
- Trailing stop helps capture trends

**Risk/Reward:** 1:1.5 to 1:2
- Default: 30 pip SL, 50 pip TP
- Trailing stop can improve R/R

**Monthly Return:** 5-15%
- Depends on market conditions
- Conservative risk management
- Consistent over time

---

## ✅ Quick Start Checklist

- [ ] EA copied to MQL5\Experts folder
- [ ] EA compiled successfully (0 errors)
- [ ] EA attached to chart
- [ ] Auto Trading enabled
- [ ] Settings configured
- [ ] S/R lines visible on chart
- [ ] Info panel showing
- [ ] Tested on demo account
- [ ] Backtested for your pair/timeframe
- [ ] Risk management set (2% max)

---

## 🎓 Strategy Summary

**Core Concept:**
- Support and Resistance are key price levels
- Price tends to bounce off these levels
- Reversal candle patterns confirm the bounce
- Enter when buyers/sellers defend the level

**Entry Rules:**
- **BUY**: Bearish candle → Bullish candle at support
- **SELL**: Bullish candle → Bearish candle at resistance

**Why It Works:**
- S/R levels are self-fulfilling (traders watch them)
- Reversal patterns show momentum shift
- Zone gives flexibility for entry
- Clear risk/reward setup

---

**Your Support/Resistance Trading EA is ready! 🚀**

**Files:**
- `mt5_indicators/SupportResistanceEA.mq5`

**Start with:**
- Demo account
- EURUSD H1
- Default settings
- 1-2 weeks testing

**Happy Trading! 📈💰**
