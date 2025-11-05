# 📊 MT5 Integration Guide - Elliott Wave Indicator & EA

## 🎯 What You Get

### 1. **Elliott Wave Indicator** (`ElliottWaveAnalyzer.mq5`)
- Displays Elliott Waves directly on MT5 charts
- Shows wave labels (1, 2, 3, 4, 5, A, B, C)
- Draws trend lines
- Highlights 20-30 pip movements
- Real-time analysis panel

### 2. **Elliott Wave Expert Advisor** (`ElliottWaveEA.mq5`)
- Automated wave detection
- Sends alerts for new waves
- Push notifications to mobile
- Email alerts
- Periodic analysis reports

---

## 📥 Installation Steps

### Step 1: Locate MT5 Data Folder

1. Open MetaTrader 5
2. Click **File** → **Open Data Folder**
3. This opens your MT5 data directory

### Step 2: Copy Indicator Files

1. Navigate to: `MQL5\Indicators\`
2. Copy `ElliottWaveAnalyzer.mq5` to this folder

### Step 3: Copy Expert Advisor Files

1. Navigate to: `MQL5\Experts\`
2. Copy `ElliottWaveEA.mq5` to this folder

### Step 4: Compile the Files

**Option A: Auto-compile**
1. Restart MT5
2. Files will compile automatically

**Option B: Manual compile**
1. In MT5, press **F4** to open MetaEditor
2. Open `ElliottWaveAnalyzer.mq5`
3. Click **Compile** button (or press F7)
4. Repeat for `ElliottWaveEA.mq5`

### Step 5: Add to Chart

**For Indicator:**
1. In MT5, go to **Navigator** panel (Ctrl+N)
2. Expand **Indicators** → **Custom**
3. Drag **ElliottWaveAnalyzer** onto your chart

**For Expert Advisor:**
1. In Navigator, expand **Expert Advisors**
2. Drag **ElliottWaveEA** onto your chart
3. Enable **Auto Trading** button in toolbar

---

## ⚙️ Configuration

### Indicator Settings

When you add the indicator, you'll see these options:

```
WaveSensitivity = 5          // Higher = fewer waves, Lower = more waves
MinPipMovement = 20          // Minimum pip movement to track
MaxPipMovement = 30          // Maximum pip movement to track
ShowWaveLabels = true        // Show wave numbers (1,2,3,A,B,C)
ShowTrendLines = true        // Show trend lines
ShowPipMovements = true      // Highlight 20-30 pip moves
ImpulseWaveColor = Yellow    // Color for impulse waves
CorrectiveWaveColor = Orange // Color for corrective waves
TrendUpColor = Lime          // Uptrend color
TrendDownColor = Red         // Downtrend color
```

### Expert Advisor Settings

```
WaveSensitivity = 5          // Wave detection sensitivity
MinPipMovement = 20          // Minimum pip movement
MaxPipMovement = 30          // Maximum pip movement
SendAlerts = true            // Pop-up alerts in MT5
SendNotifications = false    // Push to mobile app
SendEmails = false           // Email alerts
CheckInterval = 60           // Check every 60 seconds
```

---

## 📊 What You'll See on Chart

### Visual Elements:

1. **Wave Lines**
   - Yellow lines = Impulse waves (1-2-3-4-5)
   - Orange lines = Corrective waves (A-B-C)
   - Numbers/letters at wave midpoints

2. **Trend Lines**
   - Green dashed = Uptrend
   - Red dashed = Downtrend
   - Connects recent pivot points

3. **Pip Movement Boxes**
   - Dotted rectangles showing 20-30 pip moves
   - Green = Upward movement
   - Red = Downward movement

4. **Analysis Panel** (Top-left corner)
   ```
   Elliott Wave Analysis
   Total Waves: 12
   Pivot Points: 25
   Pip Range: 20-30
   Price: 1.09850
   TF: H1
   ```

---

## 🔔 Alert System (EA)

### Types of Alerts:

1. **New Wave Detected**
   - Triggers when new Elliott Wave forms
   - Shows wave type and details

2. **Pip Movement Alert**
   - Alerts when 20-30 pip movement occurs
   - Shows direction and magnitude

3. **Periodic Reports**
   - Regular analysis updates
   - Configurable interval

### Alert Channels:

- **Pop-up Alerts**: Appear in MT5 terminal
- **Push Notifications**: Sent to MT5 mobile app
- **Email Alerts**: Sent to configured email

---

## 🎨 Customization

### Change Colors:

In indicator settings, modify:
- `ImpulseWaveColor` - Color for motive waves
- `CorrectiveWaveColor` - Color for corrective waves
- `TrendUpColor` - Uptrend line color
- `TrendDownColor` - Downtrend line color

### Adjust Sensitivity:

- **Higher sensitivity (6-8)**: Fewer, larger waves
- **Lower sensitivity (3-4)**: More, smaller waves
- **Default (5)**: Balanced detection

### Pip Range:

Adjust `MinPipMovement` and `MaxPipMovement` to focus on different pip ranges:
- **10-20 pips**: Scalping
- **20-30 pips**: Day trading (default)
- **50-100 pips**: Swing trading

---

## 📱 Mobile Notifications Setup

To receive push notifications on your phone:

1. **Install MT5 Mobile App**
   - Download from App Store or Google Play
   - Login with same account as desktop

2. **Enable Notifications in EA**
   - Set `SendNotifications = true`
   - Restart EA

3. **Configure in MT5**
   - Tools → Options → Notifications
   - Enable MetaQuotes ID notifications

---

## 📧 Email Alerts Setup

To receive email alerts:

1. **Configure Email in MT5**
   - Tools → Options → Email
   - Enter SMTP settings
   - Test email connection

2. **Enable in EA**
   - Set `SendEmails = true`
   - Restart EA

---

## 🔍 Troubleshooting

### Indicator Not Showing

**Problem**: Indicator added but nothing appears on chart

**Solutions**:
1. Check if indicator is in the list (Ctrl+I)
2. Verify compilation was successful (no errors)
3. Try different timeframe (H1 recommended)
4. Increase chart history (Tools → Options → Charts)

### No Waves Detected

**Problem**: Panel shows "Total Waves: 0"

**Solutions**:
1. Lower `WaveSensitivity` (try 3 or 4)
2. Ensure sufficient price history loaded
3. Try different currency pair (EURUSD works well)
4. Check if price has enough volatility

### EA Not Sending Alerts

**Problem**: Expert Advisor running but no alerts

**Solutions**:
1. Verify `SendAlerts = true` in settings
2. Check if "Auto Trading" is enabled (toolbar button)
3. Ensure EA is attached to chart (smile icon in corner)
4. Check MT5 terminal for error messages

### Compilation Errors

**Problem**: Errors when compiling MQ5 files

**Solutions**:
1. Ensure you're using MT5 (not MT4)
2. Update MT5 to latest version
3. Check for syntax errors in code
4. Verify file is in correct folder

---

## 💡 Usage Tips

### Best Timeframes:

- **M15**: Scalping and quick trades
- **H1**: Day trading (recommended)
- **H4**: Swing trading
- **D1**: Position trading

### Best Currency Pairs:

- **EURUSD**: Most liquid, clear waves
- **GBPUSD**: Good volatility
- **USDJPY**: Clear trends
- **AUDUSD**: Smooth movements

### Trading Strategy:

1. **Wait for Wave Pattern**
   - Look for complete ABC correction
   - Or 5-wave impulse forming

2. **Confirm with Trend**
   - Check trend line direction
   - Ensure alignment with wave

3. **Use Pip Movements**
   - Enter on 20-30 pip pullback
   - Set stop loss outside pip range

4. **Target Next Wave**
   - Wave 3 target for impulse
   - Wave C target for correction

---

## 📊 Comparison: Indicator vs EA

| Feature | Indicator | Expert Advisor |
|---------|-----------|----------------|
| Visual waves on chart | ✅ Yes | ❌ No |
| Wave labels | ✅ Yes | ❌ No |
| Trend lines | ✅ Yes | ❌ No |
| Analysis panel | ✅ Yes | ❌ No |
| Alerts | ❌ No | ✅ Yes |
| Push notifications | ❌ No | ✅ Yes |
| Email alerts | ❌ No | ✅ Yes |
| Automated analysis | ❌ No | ✅ Yes |

**Recommendation**: Use **both** together!
- Indicator for visual analysis
- EA for automated alerts

---

## 🔄 Updates and Maintenance

### Updating the Code:

1. Edit `.mq5` file in MetaEditor
2. Save changes
3. Recompile (F7)
4. Restart MT5 or reload indicator/EA

### Backup Settings:

1. Right-click on chart
2. Template → Save Template
3. Name it (e.g., "Elliott Wave Setup")
4. Load template on new charts

---

## 🎓 Learning Resources

### Understanding the Display:

- **Yellow lines with numbers (1-5)**: Impulse waves (trend direction)
- **Orange lines with letters (A-C)**: Corrective waves (pullbacks)
- **Green dashed lines**: Uptrend support
- **Red dashed lines**: Downtrend resistance
- **Dotted boxes**: 20-30 pip movement zones

### Wave Rules:

1. **Wave 3 cannot be shortest** (impulse)
2. **Wave 4 cannot overlap Wave 1** (impulse)
3. **Wave 2 cannot retrace beyond Wave 1 start**
4. **ABC corrections** alternate with impulse waves

---

## 🚀 Quick Start Checklist

- [ ] MT5 installed and running
- [ ] Files copied to correct folders
- [ ] Files compiled successfully
- [ ] Indicator added to chart
- [ ] EA attached to chart (optional)
- [ ] Auto trading enabled (for EA)
- [ ] Settings configured
- [ ] Alerts tested (for EA)

---

## 📞 Support

### Common Issues:

1. **"Indicator not found"** → Check MQL5\Indicators folder
2. **"Compilation failed"** → Update MT5 to latest version
3. **"No waves showing"** → Lower sensitivity, check history
4. **"EA not working"** → Enable auto trading, check settings

### Testing:

1. Add indicator to EURUSD H1 chart
2. Should see waves within 1 minute
3. Panel should show wave count
4. Try different sensitivity if needed

---

## 🎯 Next Steps

1. **Install both indicator and EA**
2. **Test on demo account first**
3. **Adjust sensitivity to your preference**
4. **Configure alerts if using EA**
5. **Practice identifying wave patterns**
6. **Combine with other analysis tools**

---

**Your Elliott Wave analysis is now integrated directly into MT5! 📊✨**

**Files Created:**
- `mt5_indicators/ElliottWaveAnalyzer.mq5` - Visual indicator
- `mt5_indicators/ElliottWaveEA.mq5` - Expert Advisor with alerts

**Happy Trading! 📈💰**
