//+------------------------------------------------------------------+
//|                        Ultimate Multi-Strategy EA v2.0          |
//|           Complete MQL5 with Visuals, Dashboard & Elliott Wave  |
//+------------------------------------------------------------------+
#property copyright "Ultimate Multi-Strategy EA"
#property version   "2.00"
#property description "Multi-timeframe, S/R, Supply/Demand, Breakout, Elliott Wave"
#property description "With Visual Dashboard and Performance Tracking"

//--- Include files
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Global objects
CTrade trade;
CPositionInfo position;
CSymbolInfo symbolInfo;

//--- Input Parameters
input group "=== GENERAL SETTINGS ==="
input double  LotSize = 0.01;                    // Lot size
input int     MagicNumber = 123456;              // Magic number
input int     Slippage = 30;                     // Slippage in points
input bool    UseMoneyManagement = true;         // Use money management
input double  RiskPercent = 2.0;                 // Risk per trade (%)
input int     MaxSpread = 30;                    // Maximum spread (points)

input group "=== MULTI-TIMEFRAME ==="
input ENUM_TIMEFRAMES TimeFrame1 = PERIOD_M15;   // Lower timeframe
input ENUM_TIMEFRAMES TimeFrame2 = PERIOD_H1;    // Middle timeframe
input ENUM_TIMEFRAMES TimeFrame3 = PERIOD_H4;    // Higher timeframe

input group "=== STOP LOSS & TAKE PROFIT ==="
input int     StopLoss = 500;                    // Stop Loss (points)
input int     TakeProfit = 1000;                 // Take Profit (points)
input bool    UseTrailingStop = true;            // Use trailing stop
input int     TrailingStop = 300;                // Trailing stop (points)
input int     TrailingStep = 50;                 // Trailing step (points)

input group "=== SUPPORT & RESISTANCE ==="
input int     SR_Period = 20;                    // S/R lookback period
input int     SR_Strength = 3;                   // S/R strength (touches)
input double  SR_Zone = 200;                     // S/R zone (points)

input group "=== SUPPLY & DEMAND ==="
input int     SD_Period = 50;                    // Supply/Demand period
input double  SD_ZoneSize = 300;                 // Zone size (points)
input int     SD_MinCandles = 3;                 // Min candles in zone

input group "=== BREAKOUT SETTINGS ==="
input int     Breakout_Period = 20;              // Breakout period
input double  Breakout_Threshold = 1.5;          // Breakout multiplier (ATR)
input int     ATR_Period = 14;                   // ATR period

input group "=== ELLIOTT WAVE ==="
input bool    UseElliotWave = true;              // Use Elliott Wave filter
input int     Wave_Period = 100;                 // Wave analysis period
input int     WaveSensitivity = 5;               // Wave detection sensitivity

input group "=== TREND FILTERS ==="
input int     MA_Fast = 20;                      // Fast MA period
input int     MA_Slow = 50;                      // Slow MA period
input int     MA_Trend = 200;                    // Trend MA period

input group "=== TRADE MANAGEMENT ==="
input bool    OneTradePerBar = true;             // One trade per bar
input int     MaxTradesPerDay = 10;              // Max trades per day
input bool    TradeOnNewBar = true;              // Trade on new bar only
input int     StartHour = 0;                     // Start trading hour
input int     EndHour = 24;                      // End trading hour

input group "=== VISUAL DISPLAY ==="
input bool    ShowDashboard = true;              // Show dashboard
input bool    ShowSRLines = true;                // Show S/R lines
input bool    ShowZones = true;                  // Show S/D zones
input bool    ShowSignals = true;                // Show entry signals
input color   BuyColor = clrLime;                // Buy signal color
input color   SellColor = clrRed;                // Sell signal color

input group "=== ALERTS ==="
input bool    SendAlerts = true;                 // Send pop-up alerts
input bool    SendNotifications = false;         // Send push notifications
input bool    SendEmails = false;                // Send email alerts

//--- Global Variables
datetime LastBarTime = 0;
int TradesToday = 0;
datetime LastTradeDate = 0;
string prefix = "UMS_";

// Indicator handles
int handleMA_Fast1, handleMA_Slow1, handleMA_Trend1;
int handleMA_Fast2, handleMA_Slow2, handleMA_Trend2;
int handleMA_Fast3, handleMA_Slow3, handleMA_Trend3;
int handleATR;

// S/R levels
double supportLevel = 0;
double resistanceLevel = 0;

// Performance tracking
int totalTrades = 0;
int winningTrades = 0;
int losingTrades = 0;
double totalProfit = 0;
double totalLoss = 0;

// Strategy performance
int srTrades = 0, srWins = 0;
int sdTrades = 0, sdWins = 0;
int breakoutTrades = 0, breakoutWins = 0;
int waveTrades = 0, waveWins = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("Ultimate Multi-Strategy EA v2.0");
   Print("========================================");
   
   // Set magic number
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   
   // Initialize symbol info
   symbolInfo.Name(_Symbol);
   symbolInfo.Refresh();
   
   // Create indicator handles for TimeFrame1
   handleMA_Fast1 = iMA(_Symbol, TimeFrame1, MA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Slow1 = iMA(_Symbol, TimeFrame1, MA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Trend1 = iMA(_Symbol, TimeFrame1, MA_Trend, 0, MODE_SMA, PRICE_CLOSE);
   
   // Create indicator handles for TimeFrame2
   handleMA_Fast2 = iMA(_Symbol, TimeFrame2, MA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Slow2 = iMA(_Symbol, TimeFrame2, MA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Trend2 = iMA(_Symbol, TimeFrame2, MA_Trend, 0, MODE_SMA, PRICE_CLOSE);
   
   // Create indicator handles for TimeFrame3
   handleMA_Fast3 = iMA(_Symbol, TimeFrame3, MA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Slow3 = iMA(_Symbol, TimeFrame3, MA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Trend3 = iMA(_Symbol, TimeFrame3, MA_Trend, 0, MODE_SMA, PRICE_CLOSE);
   
   // Create ATR handle
   handleATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   
   // Check handles
   if(handleMA_Fast1 == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Error creating indicators!");
      return(INIT_FAILED);
   }
   
   Print("Symbol: ", _Symbol);
   Print("Timeframes: ", EnumToString(TimeFrame1), ", ", EnumToString(TimeFrame2), ", ", EnumToString(TimeFrame3));
   Print("Risk: ", RiskPercent, "%");
   Print("========================================");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   IndicatorRelease(handleMA_Fast1);
   IndicatorRelease(handleMA_Slow1);
   IndicatorRelease(handleMA_Trend1);
   IndicatorRelease(handleMA_Fast2);
   IndicatorRelease(handleMA_Slow2);
   IndicatorRelease(handleMA_Trend2);
   IndicatorRelease(handleMA_Fast3);
   IndicatorRelease(handleMA_Slow3);
   IndicatorRelease(handleMA_Trend3);
   IndicatorRelease(handleATR);
   
   // Clean up chart objects
   DeleteAllObjects();
   
   Print("EA Removed. Reason: ", reason);
   Print("Total Trades: ", totalTrades);
   Print("Win Rate: ", (totalTrades > 0 ? (winningTrades * 100.0 / totalTrades) : 0), "%");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if new bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool isNewBar = (currentBarTime != LastBarTime);
   
   if(TradeOnNewBar && !isNewBar)
   {
      // Update dashboard even if not new bar
      if(ShowDashboard)
         UpdateDashboard();
      return;
   }
   
   LastBarTime = currentBarTime;
   
   // Reset daily trade counter
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   MqlDateTime lastDt;
   TimeToStruct(LastTradeDate, lastDt);
   
   if(dt.day != lastDt.day)
   {
      TradesToday = 0;
      LastTradeDate = TimeCurrent();
   }
   
   // Check trading conditions
   if(!IsTradingAllowed())
   {
      if(ShowDashboard)
         UpdateDashboard();
      return;
   }
   
   // Update trailing stops
   if(UseTrailingStop)
      UpdateTrailingStops();
   
   // Update visual display
   if(ShowSRLines || ShowZones)
      DrawSupportResistance();
   
   if(ShowDashboard)
      UpdateDashboard();
   
   // Check if we can open new trade
   if(CountOpenTrades() > 0 && OneTradePerBar)
      return;
   
   if(TradesToday >= MaxTradesPerDay)
      return;
   
   // === PHASE 1: Multi-timeframe trend alignment ===
   int trend1 = GetTrend(TimeFrame1, handleMA_Fast1, handleMA_Slow1, handleMA_Trend1);
   int trend2 = GetTrend(TimeFrame2, handleMA_Fast2, handleMA_Slow2, handleMA_Trend2);
   int trend3 = GetTrend(TimeFrame3, handleMA_Fast3, handleMA_Slow3, handleMA_Trend3);
   
   // All timeframes must align
   bool bullishTrend = (trend1 == 1 && trend2 == 1 && trend3 == 1);
   bool bearishTrend = (trend1 == -1 && trend2 == -1 && trend3 == -1);
   
   if(!bullishTrend && !bearishTrend)
      return; // No trend alignment
   
   // === PHASE 2: Get strategy signals ===
   int srSignal = CheckSupportResistance();
   int sdSignal = CheckSupplyDemand();
   int breakoutSignal = CheckBreakout();
   int elliotSignal = UseElliotWave ? CheckElliotWave() : 0;
   
   // === PHASE 3: Score-based approach ===
   double buyScore = 0;
   double sellScore = 0;
   
   // Weighted scoring (more reliable strategies get higher weight)
   if(srSignal == 1) buyScore += 2.0;        // S/R very reliable
   if(srSignal == -1) sellScore += 2.0;
   
   if(sdSignal == 1) buyScore += 2.0;        // S/D very reliable
   if(sdSignal == -1) sellScore += 2.0;
   
   if(breakoutSignal == 1) buyScore += 1.5;  // Breakout needs confirmation
   if(breakoutSignal == -1) sellScore += 1.5;
   
   if(elliotSignal == 1) buyScore += 1.0;    // Elliott Wave as filter
   if(elliotSignal == -1) sellScore += 1.0;
   
   // === PHASE 4: Entry logic ===
   // Need trend alignment + at least 4 points (2 strong strategies)
   if(bullishTrend && buyScore >= 4.0)
   {
      if(CheckVolatility() && CheckSpread())
      {
         string signals = GetSignalString(srSignal, sdSignal, breakoutSignal, elliotSignal, true);
         OpenTrade(ORDER_TYPE_BUY, signals);
      }
   }
   else if(bearishTrend && sellScore >= 4.0)
   {
      if(CheckVolatility() && CheckSpread())
      {
         string signals = GetSignalString(srSignal, sdSignal, breakoutSignal, elliotSignal, false);
         OpenTrade(ORDER_TYPE_SELL, signals);
      }
   }
}
//+------------------------------------------------------------------+//
| Check if trading is allowed                                        |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(dt.hour < StartHour || dt.hour >= EndHour)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get trend direction for timeframe                                  |
//+------------------------------------------------------------------+
int GetTrend(ENUM_TIMEFRAMES tf, int handleFast, int handleSlow, int handleTrend)
{
   double maFast[], maSlow[], maTrend[], close[];
   
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   ArraySetAsSeries(maTrend, true);
   ArraySetAsSeries(close, true);
   
   if(CopyBuffer(handleFast, 0, 0, 2, maFast) != 2) return 0;
   if(CopyBuffer(handleSlow, 0, 0, 2, maSlow) != 2) return 0;
   if(CopyBuffer(handleTrend, 0, 0, 2, maTrend) != 2) return 0;
   if(CopyClose(_Symbol, tf, 0, 2, close) != 2) return 0;
   
   if(maFast[0] > maSlow[0] && close[0] > maTrend[0])
      return 1;  // Bullish
   else if(maFast[0] < maSlow[0] && close[0] < maTrend[0])
      return -1; // Bearish
   
   return 0; // Neutral
}

//+------------------------------------------------------------------+
//| Check Support and Resistance levels                                |
//+------------------------------------------------------------------+
int CheckSupportResistance()
{
   double high[], low[], close[], open[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, SR_Period, high) != SR_Period) return 0;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, SR_Period, low) != SR_Period) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close) != 3) return 0;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 3, open) != 3) return 0;
   
   // Find resistance and support
   resistanceLevel = high[ArrayMaximum(high, 0, SR_Period)];
   supportLevel = low[ArrayMinimum(low, 0, SR_Period)];
   
   double currentPrice = close[0];
   double point = symbolInfo.Point();
   
   // Price bouncing off support
   if(MathAbs(currentPrice - supportLevel) <= SR_Zone * point)
   {
      // Previous bearish, current bullish = buyers defending
      if(close[1] < open[1] && close[0] > open[0])
      {
         srTrades++;
         return 1; // Buy signal
      }
   }
   
   // Price bouncing off resistance
   if(MathAbs(currentPrice - resistanceLevel) <= SR_Zone * point)
   {
      // Previous bullish, current bearish = sellers defending
      if(close[1] > open[1] && close[0] < open[0])
      {
         srTrades++;
         return -1; // Sell signal
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check Supply and Demand zones                                      |
//+------------------------------------------------------------------+
int CheckSupplyDemand()
{
   double high[], low[], close[], open[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, SD_Period, high) != SD_Period) return 0;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, SD_Period, low) != SD_Period) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 2, close) != 2) return 0;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 2, open) != 2) return 0;
   
   double currentPrice = close[0];
   double point = symbolInfo.Point();
   
   // Find demand zone (strong buying area)
   for(int i = 1; i < SD_Period; i++)
   {
      double zoneLow = low[i];
      double zoneHigh = zoneLow + (SD_ZoneSize * point);
      
      if(currentPrice >= zoneLow && currentPrice <= zoneHigh)
      {
         // Confirm with bullish rejection
         if(close[0] > open[0] && low[0] <= zoneHigh)
         {
            sdTrades++;
            return 1; // Buy signal
         }
      }
   }
   
   // Find supply zone (strong selling area)
   for(int i = 1; i < SD_Period; i++)
   {
      double zoneHigh = high[i];
      double zoneLow = zoneHigh - (SD_ZoneSize * point);
      
      if(currentPrice >= zoneLow && currentPrice <= zoneHigh)
      {
         // Confirm with bearish rejection
         if(close[0] < open[0] && high[0] >= zoneLow)
         {
            sdTrades++;
            return -1; // Sell signal
         }
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check Breakout strategy                                            |
//+------------------------------------------------------------------+
int CheckBreakout()
{
   double atr[], close[];
   
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(close, true);
   
   if(CopyBuffer(handleATR, 0, 0, 3, atr) != 3) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, Breakout_Period + 2, close) != Breakout_Period + 2) return 0;
   
   // Find highest high and lowest low
   int highestIdx = ArrayMaximum(close, 1, Breakout_Period);
   int lowestIdx = ArrayMinimum(close, 1, Breakout_Period);
   
   double highestHigh = close[highestIdx];
   double lowestLow = close[lowestIdx];
   
   double currentPrice = close[0];
   double prevPrice = close[1];
   
   // Bullish breakout with volatility confirmation
   if(prevPrice <= highestHigh && currentPrice > highestHigh)
   {
      if(atr[0] > atr[1] * Breakout_Threshold)
      {
         breakoutTrades++;
         return 1; // Buy signal
      }
   }
   
   // Bearish breakout with volatility confirmation
   if(prevPrice >= lowestLow && currentPrice < lowestLow)
   {
      if(atr[0] > atr[1] * Breakout_Threshold)
      {
         breakoutTrades++;
         return -1; // Sell signal
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Enhanced Elliott Wave pattern detection                          |
//+------------------------------------------------------------------+
int CheckElliotWave()
{
   double high[], low[], close[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, Wave_Period, high) != Wave_Period) return 0;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, Wave_Period, low) != Wave_Period) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, Wave_Period, close) != Wave_Period) return 0;
   
   // Find pivot points
   int swingHighs = 0;
   int swingLows = 0;
   
   for(int i = WaveSensitivity; i < 30; i++)
   {
      // Check for swing high
      bool isHigh = true;
      for(int j = 1; j <= WaveSensitivity; j++)
      {
         if(high[i] < high[i-j] || high[i] < high[i+j])
         {
            isHigh = false;
            break;
         }
      }
      if(isHigh) swingHighs++;
      
      // Check for swing low
      bool isLow = true;
      for(int j = 1; j <= WaveSensitivity; j++)
      {
         if(low[i] > low[i-j] || low[i] > low[i+j])
         {
            isLow = false;
            break;
         }
      }
      if(isLow) swingLows++;
   }
   
   // Look for wave 5 completion (potential reversal)
   if(swingHighs >= 3 && close[0] < close[5])
   {
      waveTrades++;
      return -1; // Potential top, sell signal
   }
   
   if(swingLows >= 3 && close[0] > close[5])
   {
      waveTrades++;
      return 1; // Potential bottom, buy signal
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check volatility                                                   |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(handleATR, 0, 0, 1, atr) != 1) return false;
   
   double minATR = 0.0001 * symbolInfo.Point();
   return (atr[0] > minATR);
}

//+------------------------------------------------------------------+
//| Check spread                                                       |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spread <= MaxSpread);
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                   |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   if(!UseMoneyManagement)
      return LotSize;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();
   double point = symbolInfo.Point();
   
   double stopLossPoints = StopLoss * point;
   double lotSize = riskAmount / (stopLossPoints / tickSize * tickValue);
   
   // Normalize lot size
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Get signal string for display                                     |
//+------------------------------------------------------------------+
string GetSignalString(int sr, int sd, int bo, int ew, bool isBuy)
{
   string signals = "";
   
   if(sr != 0) signals += "S/R ";
   if(sd != 0) signals += "S/D ";
   if(bo != 0) signals += "Breakout ";
   if(ew != 0) signals += "Elliott ";
   
   return signals;
}

//+------------------------------------------------------------------+
//| Open trade                                                         |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, string signals)
{
   double lots = CalculateLotSize();
   double price, sl, tp;
   double point = symbolInfo.Point();
   
   if(orderType == ORDER_TYPE_BUY)
   {
      price = symbolInfo.Ask();
      sl = StopLoss > 0 ? price - StopLoss * point : 0;
      tp = TakeProfit > 0 ? price + TakeProfit * point : 0;
   }
   else
   {
      price = symbolInfo.Bid();
      sl = StopLoss > 0 ? price + StopLoss * point : 0;
      tp = TakeProfit > 0 ? price - TakeProfit * point : 0;
   }
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   string comment = "Multi-Strategy: " + signals;
   
   if(trade.PositionOpen(_Symbol, orderType, lots, price, sl, tp, comment))
   {
      TradesToday++;
      totalTrades++;
      
      Print("✅ Trade opened successfully!");
      Print("   Type: ", EnumToString(orderType));
      Print("   Price: ", price);
      Print("   SL: ", sl);
      Print("   TP: ", tp);
      Print("   Lots: ", lots);
      Print("   Signals: ", signals);
      
      // Send alert
      if(SendAlerts)
      {
         string alertMsg = "Trade Opened: " + EnumToString(orderType) + "\n";
         alertMsg += "Price: " + DoubleToString(price, _Digits) + "\n";
         alertMsg += "Signals: " + signals;
         Alert(alertMsg);
      }
      
      if(SendNotifications)
         SendNotification("Trade: " + EnumToString(orderType) + " - " + signals);
      
      // Draw signal arrow
      if(ShowSignals)
         DrawSignalArrow(orderType, price);
   }
   else
   {
      Print("❌ Trade failed! Error: ", GetLastError());
      Print("   Return code: ", trade.ResultRetcode());
   }
}

//+------------------------------------------------------------------+
//| Count open trades                                                  |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            count++;
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Update trailing stops                                              |
//+------------------------------------------------------------------+
void UpdateTrailingStops()
{
   double point = symbolInfo.Point();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() != _Symbol || position.Magic() != MagicNumber)
            continue;
         
         double currentSL = position.StopLoss();
         double currentTP = position.TakeProfit();
         
         if(position.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = symbolInfo.Bid();
            double newSL = bid - TrailingStop * point;
            
            if(newSL > currentSL + TrailingStep * point && newSL < bid)
            {
               trade.PositionModify(position.Ticket(), newSL, currentTP);
            }
         }
         else if(position.PositionType() == POSITION_TYPE_SELL)
         {
            double ask = symbolInfo.Ask();
            double newSL = ask + TrailingStop * point;
            
            if((newSL < currentSL - TrailingStep * point || currentSL == 0) && newSL > ask)
            {
               trade.PositionModify(position.Ticket(), newSL, currentTP);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+//| Dr
aw Support and Resistance on Chart                            |
//+------------------------------------------------------------------+
void DrawSupportResistance()
{
   if(ShowSRLines)
   {
      // Support line
      ObjectDelete(0, prefix + "Support");
      ObjectCreate(0, prefix + "Support", OBJ_HLINE, 0, 0, supportLevel);
      ObjectSetInteger(0, prefix + "Support", OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, prefix + "Support", OBJPROP_WIDTH, 2);
      ObjectSetString(0, prefix + "Support", OBJPROP_TEXT, "Support: " + DoubleToString(supportLevel, _Digits));
      
      // Resistance line
      ObjectDelete(0, prefix + "Resistance");
      ObjectCreate(0, prefix + "Resistance", OBJ_HLINE, 0, 0, resistanceLevel);
      ObjectSetInteger(0, prefix + "Resistance", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, prefix + "Resistance", OBJPROP_WIDTH, 2);
      ObjectSetString(0, prefix + "Resistance", OBJPROP_TEXT, "Resistance: " + DoubleToString(resistanceLevel, _Digits));
   }
   
   if(ShowZones)
   {
      double point = symbolInfo.Point();
      datetime time1 = iTime(_Symbol, PERIOD_CURRENT, SR_Period);
      datetime time2 = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * 10;
      
      // Support zone
      ObjectDelete(0, prefix + "SupportZone");
      ObjectCreate(0, prefix + "SupportZone", OBJ_RECTANGLE, 0, 
                   time1, supportLevel - SR_Zone * point,
                   time2, supportLevel + SR_Zone * point);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_FILL, true);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_BACK, true);
      
      // Resistance zone
      ObjectDelete(0, prefix + "ResistanceZone");
      ObjectCreate(0, prefix + "ResistanceZone", OBJ_RECTANGLE, 0,
                   time1, resistanceLevel - SR_Zone * point,
                   time2, resistanceLevel + SR_Zone * point);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_FILL, true);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
//| Draw signal arrow                                                 |
//+------------------------------------------------------------------+
void DrawSignalArrow(ENUM_ORDER_TYPE type, double price)
{
   string name = prefix + "Signal_" + IntegerToString(TimeCurrent());
   datetime time = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(type == ORDER_TYPE_BUY)
   {
      ObjectCreate(0, name, OBJ_ARROW_BUY, 0, time, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, BuyColor);
   }
   else
   {
      ObjectCreate(0, name, OBJ_ARROW_SELL, 0, time, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, SellColor);
   }
   
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
}

//+------------------------------------------------------------------+
//| Update Dashboard                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   int x = 20;
   int y = 50;
   int lineHeight = 20;
   int currentY = y;
   
   // Background panel
   ObjectDelete(0, prefix + "Panel");
   ObjectCreate(0, prefix + "Panel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XSIZE, 350);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YSIZE, 450);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_COLOR, clrWhite);
   
   // Title
   currentY += 10;
   CreateLabel(prefix + "Title", x + 10, currentY, "ULTIMATE MULTI-STRATEGY EA v2.0", clrYellow, 11, true);
   
   // Separator
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep1", x + 10, currentY, "═══════════════════════════════", clrGray, 8, false);
   
   // Multi-Timeframe Status
   currentY += lineHeight;
   CreateLabel(prefix + "MTF", x + 10, currentY, "MULTI-TIMEFRAME ANALYSIS", clrAqua, 9, true);
   
   int trend1 = GetTrend(TimeFrame1, handleMA_Fast1, handleMA_Slow1, handleMA_Trend1);
   int trend2 = GetTrend(TimeFrame2, handleMA_Fast2, handleMA_Slow2, handleMA_Trend2);
   int trend3 = GetTrend(TimeFrame3, handleMA_Fast3, handleMA_Slow3, handleMA_Trend3);
   
   currentY += lineHeight;
   string tf1Status = EnumToString(TimeFrame1) + ": " + GetTrendString(trend1);
   color tf1Color = GetTrendColor(trend1);
   CreateLabel(prefix + "TF1", x + 10, currentY, tf1Status, tf1Color, 8, false);
   
   currentY += lineHeight;
   string tf2Status = EnumToString(TimeFrame2) + ": " + GetTrendString(trend2);
   color tf2Color = GetTrendColor(trend2);
   CreateLabel(prefix + "TF2", x + 10, currentY, tf2Status, tf2Color, 8, false);
   
   currentY += lineHeight;
   string tf3Status = EnumToString(TimeFrame3) + ": " + GetTrendString(trend3);
   color tf3Color = GetTrendColor(trend3);
   CreateLabel(prefix + "TF3", x + 10, currentY, tf3Status, tf3Color, 8, false);
   
   // Separator
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep2", x + 10, currentY, "═══════════════════════════════", clrGray, 8, false);
   
   // Strategy Signals
   currentY += lineHeight;
   CreateLabel(prefix + "Signals", x + 10, currentY, "STRATEGY SIGNALS", clrAqua, 9, true);
   
   currentY += lineHeight;
   CreateLabel(prefix + "SR", x + 10, currentY, "Support/Resistance: " + IntegerToString(srTrades) + " trades", clrWhite, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "SD", x + 10, currentY, "Supply/Demand: " + IntegerToString(sdTrades) + " trades", clrWhite, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "BO", x + 10, currentY, "Breakout: " + IntegerToString(breakoutTrades) + " trades", clrWhite, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "EW", x + 10, currentY, "Elliott Wave: " + IntegerToString(waveTrades) + " trades", clrWhite, 8, false);
   
   // Separator
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep3", x + 10, currentY, "═══════════════════════════════", clrGray, 8, false);
   
   // Current Levels
   currentY += lineHeight;
   CreateLabel(prefix + "Levels", x + 10, currentY, "CURRENT LEVELS", clrAqua, 9, true);
   
   currentY += lineHeight;
   CreateLabel(prefix + "ResLevel", x + 10, currentY, "Resistance: " + DoubleToString(resistanceLevel, _Digits), clrRed, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "SupLevel", x + 10, currentY, "Support: " + DoubleToString(supportLevel, _Digits), clrLime, 8, false);
   
   currentY += lineHeight;
   double currentPrice = symbolInfo.Bid();
   CreateLabel(prefix + "Price", x + 10, currentY, "Current: " + DoubleToString(currentPrice, _Digits), clrYellow, 8, false);
   
   // Separator
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep4", x + 10, currentY, "═══════════════════════════════", clrGray, 8, false);
   
   // Performance
   currentY += lineHeight;
   CreateLabel(prefix + "Perf", x + 10, currentY, "PERFORMANCE", clrAqua, 9, true);
   
   currentY += lineHeight;
   CreateLabel(prefix + "Total", x + 10, currentY, "Total Trades: " + IntegerToString(totalTrades), clrWhite, 8, false);
   
   currentY += lineHeight;
   double winRate = totalTrades > 0 ? (winningTrades * 100.0 / totalTrades) : 0;
   color winColor = winRate >= 60 ? clrLime : (winRate >= 50 ? clrYellow : clrRed);
   CreateLabel(prefix + "WinRate", x + 10, currentY, "Win Rate: " + DoubleToString(winRate, 1) + "%", winColor, 8, false);
   
   currentY += lineHeight;
   int openTrades = CountOpenTrades();
   CreateLabel(prefix + "Open", x + 10, currentY, "Open Trades: " + IntegerToString(openTrades), clrWhite, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "Today", x + 10, currentY, "Trades Today: " + IntegerToString(TradesToday) + "/" + IntegerToString(MaxTradesPerDay), clrWhite, 8, false);
   
   // Calculate current profit
   double currentProfit = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            currentProfit += position.Profit();
      }
   }
   
   currentY += lineHeight;
   color profitColor = currentProfit >= 0 ? clrLime : clrRed;
   CreateLabel(prefix + "Profit", x + 10, currentY, "Current P/L: $" + DoubleToString(currentProfit, 2), profitColor, 8, false);
   
   // Separator
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep5", x + 10, currentY, "═══════════════════════════════", clrGray, 8, false);
   
   // Risk Info
   currentY += lineHeight;
   CreateLabel(prefix + "Risk", x + 10, currentY, "RISK MANAGEMENT", clrAqua, 9, true);
   
   currentY += lineHeight;
   CreateLabel(prefix + "LotSize", x + 10, currentY, "Lot Size: " + DoubleToString(CalculateLotSize(), 2), clrWhite, 8, false);
   
   currentY += lineHeight;
   CreateLabel(prefix + "RiskPct", x + 10, currentY, "Risk: " + DoubleToString(RiskPercent, 1) + "%", clrWhite, 8, false);
   
   currentY += lineHeight;
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   color spreadColor = spread <= MaxSpread ? clrLime : clrRed;
   CreateLabel(prefix + "Spread", x + 10, currentY, "Spread: " + IntegerToString(spread) + " pts", spreadColor, 8, false);
}

//+------------------------------------------------------------------+
//| Create Label Helper                                              |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int size, bool bold)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   if(bold)
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

//+------------------------------------------------------------------+
//| Get trend string                                                  |
//+------------------------------------------------------------------+
string GetTrendString(int trend)
{
   if(trend == 1) return "BULLISH ▲";
   if(trend == -1) return "BEARISH ▼";
   return "NEUTRAL ─";
}

//+------------------------------------------------------------------+
//| Get trend color                                                   |
//+------------------------------------------------------------------+
color GetTrendColor(int trend)
{
   if(trend == 1) return clrLime;
   if(trend == -1) return clrRed;
   return clrYellow;
}

//+------------------------------------------------------------------+
//| Delete all objects                                               |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| On Trade Event - Track Performance                               |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Update performance statistics
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
         {
            double profit = position.Profit();
            
            if(profit > 0)
            {
               winningTrades++;
               totalProfit += profit;
            }
            else if(profit < 0)
            {
               losingTrades++;
               totalLoss += MathAbs(profit);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+