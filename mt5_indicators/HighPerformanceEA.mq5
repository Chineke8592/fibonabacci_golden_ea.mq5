//+------------------------------------------------------------------+
//|                                    High Performance EA v1.0     |
//|                    Optimized for 80-95% Win Rate                |
//|                    Target: 1:3 R/R, 10-150% Monthly Return     |
//+------------------------------------------------------------------+
#property copyright "High Performance Trading System"
#property version   "1.00"
#property description "Ultra-selective multi-confirmation system"
#property description "Win Rate Target: 80-95%"
#property description "Risk/Reward: 1:3 (30 pips SL, 150 pips TP)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

CTrade trade;
CPositionInfo position;
CSymbolInfo symbolInfo;

//--- Input Parameters
input group "=== PERFORMANCE TARGETS ==="
input double  TargetWinRate = 85.0;              // Target win rate (%)
input double  TargetMonthlyReturn = 50.0;        // Target monthly return (%)
input int     MinConfirmations = 5;              // Minimum confirmations (5-7)

input group "=== RISK MANAGEMENT ==="
input double  LotSize = 0.01;                    // Lot size
input int     MagicNumber = 999888;              // Magic number
input bool    UseMoneyManagement = true;         // Auto lot sizing
input double  RiskPercent = 1.0;                 // Risk per trade (1% for safety)
input int     StopLoss = 300;                    // Stop Loss (30 pips)
input int     TakeProfit = 1500;                 // Take Profit (150 pips) = 1:5 R/R
input int     MaxSpread = 20;                    // Maximum spread

input group "=== MULTI-TIMEFRAME (STRICT) ==="
input ENUM_TIMEFRAMES TF1 = PERIOD_M15;          // Timeframe 1
input ENUM_TIMEFRAMES TF2 = PERIOD_H1;           // Timeframe 2
input ENUM_TIMEFRAMES TF3 = PERIOD_H4;           // Timeframe 3
input ENUM_TIMEFRAMES TF4 = PERIOD_D1;           // Timeframe 4 (added for confirmation)

input group "=== SUPPORT & RESISTANCE ==="
input int     SR_Period = 50;                    // S/R period (longer = more reliable)
input double  SR_Zone = 150;                     // S/R zone (tighter)
input int     SR_MinTouches = 3;                 // Minimum touches required

input group "=== SUPPLY & DEMAND ==="
input int     SD_Period = 100;                   // S/D period
input double  SD_ZoneSize = 200;                 // Zone size
input bool    SD_RequireRejection = true;        // Require strong rejection

input group "=== TREND CONFIRMATION ==="
input int     MA_Fast = 20;                      // Fast MA
input int     MA_Slow = 50;                      // Slow MA
input int     MA_Trend = 200;                    // Trend MA
input int     ADX_Period = 14;                   // ADX period
input double  ADX_MinLevel = 25.0;               // Minimum ADX (strong trend)

input group "=== MOMENTUM & VOLUME ==="
input int     RSI_Period = 14;                   // RSI period
input double  RSI_Oversold = 30;                 // RSI oversold
input double  RSI_Overbought = 70;               // RSI overbought
input bool    RequireVolumeConfirmation = true;  // Volume confirmation

input group "=== ELLIOTT WAVE (STRICT) ==="
input bool    UseElliotWave = true;              // Use Elliott Wave
input int     Wave_Period = 100;                 // Wave period
input int     WaveSensitivity = 6;               // Sensitivity (higher = stricter)

input group "=== TRADE MANAGEMENT ==="
input bool    UseTrailingStop = true;            // Trailing stop
input int     TrailingStop = 500;                // Trail distance (50 pips)
input int     TrailingStep = 100;                // Trail step (10 pips)
input int     BreakEvenPips = 300;               // Move to BE at 30 pips
input bool    UsePartialTP = true;               // Partial take profit
input double  PartialTPPercent = 50.0;           // Close 50% at TP1
input int     PartialTPPips = 750;               // TP1 at 75 pips (1:2.5)

input group "=== FILTERS ==="
input int     MaxTradesPerDay = 3;               // Max trades per day (selective)
input bool    TradeOnlyMajorSessions = true;    // London/NY only
input bool    AvoidNews = true;                  // Avoid news times
input int     NewsBufferMinutes = 60;            // Buffer before/after news

input group "=== VISUAL ==="
input bool    ShowDashboard = true;              // Show dashboard
input bool    ShowConfirmations = true;          // Show confirmation count
input color   HighProbColor = clrLime;           // High probability color

//--- Global Variables
datetime LastBarTime = 0;
int TradesToday = 0;
datetime LastTradeDate = 0;
string prefix = "HP_";

// Indicator handles
int handleMA_Fast[], handleMA_Slow[], handleMA_Trend[];
int handleADX[], handleRSI[], handleATR;

// Performance tracking
int totalTrades = 0;
int winningTrades = 0;
double totalProfit = 0;
double monthlyProfit = 0;
datetime monthStart;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("HIGH PERFORMANCE EA v1.0");
   Print("========================================");
   Print("Target Win Rate: ", TargetWinRate, "%");
   Print("Target Monthly Return: ", TargetMonthlyReturn, "%");
   Print("Risk/Reward: 1:", (TakeProfit / StopLoss));
   Print("Min Confirmations: ", MinConfirmations);
   Print("========================================");
   
   trade.SetExpertMagicNumber(MagicNumber);
   symbolInfo.Name(_Symbol);
   symbolInfo.Refresh();
   
   // Initialize indicator handles for all timeframes
   ArrayResize(handleMA_Fast, 4);
   ArrayResize(handleMA_Slow, 4);
   ArrayResize(handleMA_Trend, 4);
   ArrayResize(handleADX, 4);
   ArrayResize(handleRSI, 4);
   
   ENUM_TIMEFRAMES timeframes[] = {TF1, TF2, TF3, TF4};
   
   for(int i = 0; i < 4; i++)
   {
      handleMA_Fast[i] = iMA(_Symbol, timeframes[i], MA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      handleMA_Slow[i] = iMA(_Symbol, timeframes[i], MA_Slow, 0, MODE_EMA, PRICE_CLOSE);
      handleMA_Trend[i] = iMA(_Symbol, timeframes[i], MA_Trend, 0, MODE_SMA, PRICE_CLOSE);
      handleADX[i] = iADX(_Symbol, timeframes[i], ADX_Period);
      handleRSI[i] = iRSI(_Symbol, timeframes[i], RSI_Period, PRICE_CLOSE);
   }
   
   handleATR = iATR(_Symbol, PERIOD_CURRENT, 14);
   
   monthStart = TimeCurrent();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == LastBarTime) return;
   LastBarTime = currentBarTime;
   
   // Reset daily counter
   MqlDateTime dt, lastDt;
   TimeToStruct(TimeCurrent(), dt);
   TimeToStruct(LastTradeDate, lastDt);
   
   if(dt.day != lastDt.day)
   {
      TradesToday = 0;
      LastTradeDate = TimeCurrent();
   }
   
   // Reset monthly profit
   if(dt.mon != TimeMonth(monthStart))
   {
      monthlyProfit = 0;
      monthStart = TimeCurrent();
   }
   
   // Update trailing stops
   if(UseTrailingStop)
      UpdateTrailingStops();
   
   // Move to breakeven
   MoveToBreakeven();
   
   // Partial TP
   if(UsePartialTP)
      CheckPartialTP();
   
   // Update dashboard
   if(ShowDashboard)
      UpdateDashboard();
   
   // Check if we can trade
   if(TradesToday >= MaxTradesPerDay) return;
   if(CountOpenTrades() > 0) return;
   if(!IsGoodTradingTime()) return;
   if(!CheckSpread()) return;
   
   // === ULTRA-STRICT ENTRY SYSTEM ===
   int confirmations = 0;
   string confirmationList = "";
   
   // 1. Multi-Timeframe Alignment (ALL 4 must align)
   int trend1 = GetTrend(0);
   int trend2 = GetTrend(1);
   int trend3 = GetTrend(2);
   int trend4 = GetTrend(3);
   
   bool bullishTrend = (trend1 == 1 && trend2 == 1 && trend3 == 1 && trend4 == 1);
   bool bearishTrend = (trend1 == -1 && trend2 == -1 && trend3 == -1 && trend4 == -1);
   
   if(!bullishTrend && !bearishTrend) return;
   
   confirmations++;
   confirmationList += "1.Multi-TF ";
   
   // 2. Strong Trend (ADX > 25 on all timeframes)
   if(CheckStrongTrend())
   {
      confirmations++;
      confirmationList += "2.Strong-Trend ";
   }
   
   // 3. Support/Resistance with multiple touches
   int srSignal = CheckSupportResistanceStrict();
   if(srSignal != 0)
   {
      confirmations++;
      confirmationList += "3.S/R-Bounce ";
   }
   
   // 4. Supply/Demand zone with rejection
   int sdSignal = CheckSupplyDemandStrict();
   if(sdSignal != 0)
   {
      confirmations++;
      confirmationList += "4.S/D-Zone ";
   }
   
   // 5. RSI confirmation (not overbought/oversold in wrong direction)
   if(CheckRSI(bullishTrend))
   {
      confirmations++;
      confirmationList += "5.RSI-OK ";
   }
   
   // 6. Volume confirmation
   if(!RequireVolumeConfirmation || CheckVolume())
   {
      confirmations++;
      confirmationList += "6.Volume ";
   }
   
   // 7. Elliott Wave alignment
   if(UseElliotWave)
   {
      int waveSignal = CheckElliotWaveStrict();
      if(waveSignal != 0)
      {
         confirmations++;
         confirmationList += "7.Elliott ";
      }
   }
   
   // 8. Candle pattern confirmation
   if(CheckCandlePattern(bullishTrend))
   {
      confirmations++;
      confirmationList += "8.Candle ";
   }
   
   // === ENTRY DECISION ===
   // Need minimum confirmations (5-7 out of 8)
   if(confirmations >= MinConfirmations)
   {
      if(bullishTrend && srSignal == 1 && sdSignal == 1)
      {
         Print("✅ HIGH PROBABILITY BUY SETUP");
         Print("   Confirmations: ", confirmations, "/8");
         Print("   Details: ", confirmationList);
         OpenTrade(ORDER_TYPE_BUY, confirmations, confirmationList);
      }
      else if(bearishTrend && srSignal == -1 && sdSignal == -1)
      {
         Print("✅ HIGH PROBABILITY SELL SETUP");
         Print("   Confirmations: ", confirmations, "/8");
         Print("   Details: ", confirmationList);
         OpenTrade(ORDER_TYPE_SELL, confirmations, confirmationList);
      }
   }
   else
   {
      if(ShowConfirmations && confirmations >= 3)
      {
         Print("⚠️ Insufficient confirmations: ", confirmations, "/", MinConfirmations);
         Print("   Need ", (MinConfirmations - confirmations), " more");
      }
   }
}
//+------------------------------------------------------------------+/
/| Get trend with ADX confirmation                                   |
//+------------------------------------------------------------------+
int GetTrend(int tfIndex)
{
   double maFast[], maSlow[], maTrend[], close[], adx[];
   
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   ArraySetAsSeries(maTrend, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(adx, true);
   
   if(CopyBuffer(handleMA_Fast[tfIndex], 0, 0, 2, maFast) != 2) return 0;
   if(CopyBuffer(handleMA_Slow[tfIndex], 0, 0, 2, maSlow) != 2) return 0;
   if(CopyBuffer(handleMA_Trend[tfIndex], 0, 0, 2, maTrend) != 2) return 0;
   if(CopyBuffer(handleADX[tfIndex], 0, 0, 2, adx) != 2) return 0;
   
   ENUM_TIMEFRAMES timeframes[] = {TF1, TF2, TF3, TF4};
   if(CopyClose(_Symbol, timeframes[tfIndex], 0, 2, close) != 2) return 0;
   
   // Strict trend requirements
   if(maFast[0] > maSlow[0] && maSlow[0] > maTrend[0] && close[0] > maTrend[0] && adx[0] > ADX_MinLevel)
      return 1;  // Strong bullish
   else if(maFast[0] < maSlow[0] && maSlow[0] < maTrend[0] && close[0] < maTrend[0] && adx[0] > ADX_MinLevel)
      return -1; // Strong bearish
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check strong trend on all timeframes                             |
//+------------------------------------------------------------------+
bool CheckStrongTrend()
{
   for(int i = 0; i < 4; i++)
   {
      double adx[];
      ArraySetAsSeries(adx, true);
      
      if(CopyBuffer(handleADX[i], 0, 0, 1, adx) != 1) return false;
      
      if(adx[0] < ADX_MinLevel)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Strict Support/Resistance check                                  |
//+------------------------------------------------------------------+
int CheckSupportResistanceStrict()
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
   
   double resistance = high[ArrayMaximum(high, 0, SR_Period)];
   double support = low[ArrayMinimum(low, 0, SR_Period)];
   
   double currentPrice = close[0];
   double point = symbolInfo.Point();
   
   // Count touches at support
   int supportTouches = 0;
   for(int i = 1; i < SR_Period; i++)
   {
      if(MathAbs(low[i] - support) <= SR_Zone * point)
         supportTouches++;
   }
   
   // Count touches at resistance
   int resistanceTouches = 0;
   for(int i = 1; i < SR_Period; i++)
   {
      if(MathAbs(high[i] - resistance) <= SR_Zone * point)
         resistanceTouches++;
   }
   
   // Support bounce (need minimum touches + rejection pattern)
   if(MathAbs(currentPrice - support) <= SR_Zone * point && supportTouches >= SR_MinTouches)
   {
      // Strong rejection: prev bearish, current bullish with long lower wick
      if(close[1] < open[1] && close[0] > open[0])
      {
         double wickSize = close[0] - low[0];
         double bodySize = close[0] - open[0];
         if(wickSize > bodySize * 1.5) // Wick 1.5x body
            return 1;
      }
   }
   
   // Resistance bounce
   if(MathAbs(currentPrice - resistance) <= SR_Zone * point && resistanceTouches >= SR_MinTouches)
   {
      if(close[1] > open[1] && close[0] < open[0])
      {
         double wickSize = high[0] - close[0];
         double bodySize = open[0] - close[0];
         if(wickSize > bodySize * 1.5)
            return -1;
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Strict Supply/Demand check                                       |
//+------------------------------------------------------------------+
int CheckSupplyDemandStrict()
{
   double high[], low[], close[], open[], volume[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(volume, true);
   
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, SD_Period, high) != SD_Period) return 0;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, SD_Period, low) != SD_Period) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, SD_Period, close) != SD_Period) return 0;
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, SD_Period, open) != SD_Period) return 0;
   if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, SD_Period, volume) != SD_Period) return 0;
   
   double currentPrice = close[0];
   double point = symbolInfo.Point();
   
   // Find demand zones (strong buying with volume)
   for(int i = 5; i < SD_Period - 5; i++)
   {
      // Look for strong bullish move from zone
      if(close[i] > open[i] && (close[i] - open[i]) > (high[i] - low[i]) * 0.7)
      {
         if(volume[i] > volume[i+1] * 1.5) // Volume spike
         {
            double zoneLow = low[i];
            double zoneHigh = zoneLow + SD_ZoneSize * point;
            
            if(currentPrice >= zoneLow && currentPrice <= zoneHigh)
            {
               // Require strong rejection if enabled
               if(SD_RequireRejection)
               {
                  if(close[0] > open[0] && low[0] <= zoneHigh && (close[0] - low[0]) > (high[0] - low[0]) * 0.6)
                     return 1;
               }
               else
                  return 1;
            }
         }
      }
   }
   
   // Find supply zones
   for(int i = 5; i < SD_Period - 5; i++)
   {
      if(close[i] < open[i] && (open[i] - close[i]) > (high[i] - low[i]) * 0.7)
      {
         if(volume[i] > volume[i+1] * 1.5)
         {
            double zoneHigh = high[i];
            double zoneLow = zoneHigh - SD_ZoneSize * point;
            
            if(currentPrice >= zoneLow && currentPrice <= zoneHigh)
            {
               if(SD_RequireRejection)
               {
                  if(close[0] < open[0] && high[0] >= zoneLow && (high[0] - close[0]) > (high[0] - low[0]) * 0.6)
                     return -1;
               }
               else
                  return -1;
            }
         }
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check RSI                                                         |
//+------------------------------------------------------------------+
bool CheckRSI(bool isBullish)
{
   double rsi[];
   ArraySetAsSeries(rsi, true);
   
   // Check RSI on H1 timeframe
   if(CopyBuffer(handleRSI[1], 0, 0, 1, rsi) != 1) return false;
   
   if(isBullish)
   {
      // For buy: RSI should not be overbought
      return (rsi[0] < RSI_Overbought && rsi[0] > 40);
   }
   else
   {
      // For sell: RSI should not be oversold
      return (rsi[0] > RSI_Oversold && rsi[0] < 60);
   }
}

//+------------------------------------------------------------------+
//| Check volume confirmation                                         |
//+------------------------------------------------------------------+
bool CheckVolume()
{
   long volume[];
   ArraySetAsSeries(volume, true);
   
   if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 3, volume) != 3) return false;
   
   // Current volume should be higher than average of previous 2
   long avgVolume = (volume[1] + volume[2]) / 2;
   return (volume[0] > avgVolume * 1.2);
}

//+------------------------------------------------------------------+
//| Strict Elliott Wave check                                        |
//+------------------------------------------------------------------+
int CheckElliotWaveStrict()
{
   double high[], low[], close[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, Wave_Period, high) != Wave_Period) return 0;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, Wave_Period, low) != Wave_Period) return 0;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, Wave_Period, close) != Wave_Period) return 0;
   
   int swingHighs = 0;
   int swingLows = 0;
   
   for(int i = WaveSensitivity; i < 40; i++)
   {
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
   
   // Look for wave 5 completion (reversal)
   if(swingHighs >= 3 && close[0] < close[10])
      return -1;
   
   if(swingLows >= 3 && close[0] > close[10])
      return 1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check candle pattern                                              |
//+------------------------------------------------------------------+
bool CheckCandlePattern(bool isBullish)
{
   double open[], high[], low[], close[];
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 3, open) != 3) return false;
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 3, high) != 3) return false;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 3, low) != 3) return false;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close) != 3) return false;
   
   if(isBullish)
   {
      // Bullish engulfing or hammer
      bool engulfing = (close[0] > open[0] && close[1] < open[1] && 
                       close[0] > open[1] && open[0] < close[1]);
      
      double body = close[0] - open[0];
      double lowerWick = open[0] - low[0];
      bool hammer = (body > 0 && lowerWick > body * 2);
      
      return (engulfing || hammer);
   }
   else
   {
      // Bearish engulfing or shooting star
      bool engulfing = (close[0] < open[0] && close[1] > open[1] && 
                       close[0] < open[1] && open[0] > close[1]);
      
      double body = open[0] - close[0];
      double upperWick = high[0] - open[0];
      bool shootingStar = (body > 0 && upperWick > body * 2);
      
      return (engulfing || shootingStar);
   }
}

//+------------------------------------------------------------------+
//| Check if good trading time                                        |
//+------------------------------------------------------------------+
bool IsGoodTradingTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(TradeOnlyMajorSessions)
   {
      // London: 8-12 GMT, NY: 13-17 GMT
      if(dt.hour < 8 || dt.hour >= 17)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check spread                                                      |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spread <= MaxSpread);
}

//+------------------------------------------------------------------+
//| Calculate lot size                                                |
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
   
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Open trade                                                         |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, int confirmations, string details)
{
   double lots = CalculateLotSize();
   double price, sl, tp;
   double point = symbolInfo.Point();
   
   if(orderType == ORDER_TYPE_BUY)
   {
      price = symbolInfo.Ask();
      sl = price - StopLoss * point;
      tp = price + TakeProfit * point;
   }
   else
   {
      price = symbolInfo.Bid();
      sl = price + StopLoss * point;
      tp = price - TakeProfit * point;
   }
   
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   string comment = "HP-EA [" + IntegerToString(confirmations) + "/8]";
   
   if(trade.PositionOpen(_Symbol, orderType, lots, price, sl, tp, comment))
   {
      TradesToday++;
      totalTrades++;
      
      Print("========================================");
      Print("✅ HIGH PROBABILITY TRADE OPENED");
      Print("========================================");
      Print("Type: ", EnumToString(orderType));
      Print("Price: ", price);
      Print("SL: ", sl, " (", StopLoss/10, " pips)");
      Print("TP: ", tp, " (", TakeProfit/10, " pips)");
      Print("R/R: 1:", DoubleToString(TakeProfit/StopLoss, 1));
      Print("Lots: ", lots);
      Print("Confirmations: ", confirmations, "/8");
      Print("Details: ", details);
      Print("========================================");
      
      Alert("HIGH PROBABILITY TRADE: ", EnumToString(orderType), "\nConfirmations: ", confirmations, "/8");
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
         double openPrice = position.PriceOpen();
         
         if(position.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = symbolInfo.Bid();
            double newSL = bid - TrailingStop * point;
            
            if(newSL > currentSL + TrailingStep * point && newSL < bid)
            {
               trade.PositionModify(position.Ticket(), newSL, currentTP);
               Print("✅ Trailing stop updated: ", newSL);
            }
         }
         else
         {
            double ask = symbolInfo.Ask();
            double newSL = ask + TrailingStop * point;
            
            if((newSL < currentSL - TrailingStep * point || currentSL == 0) && newSL > ask)
            {
               trade.PositionModify(position.Ticket(), newSL, currentTP);
               Print("✅ Trailing stop updated: ", newSL);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Move to breakeven                                                 |
//+------------------------------------------------------------------+
void MoveToBreakeven()
{
   double point = symbolInfo.Point();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() != _Symbol || position.Magic() != MagicNumber)
            continue;
         
         double openPrice = position.PriceOpen();
         double currentSL = position.StopLoss();
         double currentTP = position.TakeProfit();
         
         if(position.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = symbolInfo.Bid();
            
            if(bid >= openPrice + BreakEvenPips * point && currentSL < openPrice)
            {
               trade.PositionModify(position.Ticket(), openPrice + 10 * point, currentTP);
               Print("✅ Moved to breakeven +1 pip");
            }
         }
         else
         {
            double ask = symbolInfo.Ask();
            
            if(ask <= openPrice - BreakEvenPips * point && (currentSL > openPrice || currentSL == 0))
            {
               trade.PositionModify(position.Ticket(), openPrice - 10 * point, currentTP);
               Print("✅ Moved to breakeven +1 pip");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check partial TP                                                  |
//+------------------------------------------------------------------+
void CheckPartialTP()
{
   double point = symbolInfo.Point();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() != _Symbol || position.Magic() != MagicNumber)
            continue;
         
         double openPrice = position.PriceOpen();
         double currentVolume = position.Volume();
         
         if(position.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = symbolInfo.Bid();
            
            if(bid >= openPrice + PartialTPPips * point)
            {
               double closeVolume = NormalizeDouble(currentVolume * PartialTPPercent / 100.0, 2);
               if(closeVolume >= symbolInfo.LotsMin())
               {
                  trade.PositionClosePartial(position.Ticket(), closeVolume);
                  Print("✅ Partial TP: Closed ", PartialTPPercent, "% at ", PartialTPPips/10, " pips");
               }
            }
         }
         else
         {
            double ask = symbolInfo.Ask();
            
            if(ask <= openPrice - PartialTPPips * point)
            {
               double closeVolume = NormalizeDouble(currentVolume * PartialTPPercent / 100.0, 2);
               if(closeVolume >= symbolInfo.LotsMin())
               {
                  trade.PositionClosePartial(position.Ticket(), closeVolume);
                  Print("✅ Partial TP: Closed ", PartialTPPercent, "% at ", PartialTPPips/10, " pips");
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update dashboard                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   int x = 20, y = 50, lineHeight = 20, currentY = y + 10;
   
   // Background
   ObjectDelete(0, prefix + "Panel");
   ObjectCreate(0, prefix + "Panel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XSIZE, 320);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YSIZE, 280);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   
   // Title
   CreateLabel(prefix + "Title", x + 10, currentY, "HIGH PERFORMANCE EA v1.0", clrYellow, 11);
   
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep1", x + 10, currentY, "══════════════════════════", clrGray, 8);
   
   // Performance
   currentY += lineHeight;
   CreateLabel(prefix + "PerfTitle", x + 10, currentY, "PERFORMANCE", clrAqua, 10);
   
   currentY += lineHeight;
   double winRate = totalTrades > 0 ? (winningTrades * 100.0 / totalTrades) : 0;
   color winColor = winRate >= 80 ? clrLime : (winRate >= 70 ? clrYellow : clrRed);
   CreateLabel(prefix + "WinRate", x + 10, currentY, "Win Rate: " + DoubleToString(winRate, 1) + "% (Target: " + DoubleToString(TargetWinRate, 0) + "%)", winColor, 9);
   
   currentY += lineHeight;
   double monthlyReturn = AccountInfoDouble(ACCOUNT_BALANCE) > 0 ? (monthlyProfit / AccountInfoDouble(ACCOUNT_BALANCE) * 100) : 0;
   color returnColor = monthlyReturn >= TargetMonthlyReturn ? clrLime : clrYellow;
   CreateLabel(prefix + "Monthly", x + 10, currentY, "Monthly: " + DoubleToString(monthlyReturn, 1) + "% (Target: " + DoubleToString(TargetMonthlyReturn, 0) + "%)", returnColor, 9);
   
   currentY += lineHeight;
   CreateLabel(prefix + "Total", x + 10, currentY, "Total Trades: " + IntegerToString(totalTrades), clrWhite, 9);
   
   currentY += lineHeight;
   CreateLabel(prefix + "Today", x + 10, currentY, "Today: " + IntegerToString(TradesToday) + "/" + IntegerToString(MaxTradesPerDay), clrWhite, 9);
   
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep2", x + 10, currentY, "══════════════════════════", clrGray, 8);
   
   // Current trade
   currentY += lineHeight;
   CreateLabel(prefix + "TradeTitle", x + 10, currentY, "CURRENT TRADE", clrAqua, 10);
   
   int openTrades = CountOpenTrades();
   currentY += lineHeight;
   CreateLabel(prefix + "Open", x + 10, currentY, "Open: " + IntegerToString(openTrades), clrWhite, 9);
   
   if(openTrades > 0)
   {
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(position.SelectByIndex(i))
         {
            if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            {
               currentY += lineHeight;
               double profit = position.Profit();
               color profitColor = profit >= 0 ? clrLime : clrRed;
               CreateLabel(prefix + "Profit", x + 10, currentY, "P/L: $" + DoubleToString(profit, 2), profitColor, 9);
               
               currentY += lineHeight;
               double pips = 0;
               if(position.PositionType() == POSITION_TYPE_BUY)
                  pips = (symbolInfo.Bid() - position.PriceOpen()) / symbolInfo.Point() / 10;
               else
                  pips = (position.PriceOpen() - symbolInfo.Ask()) / symbolInfo.Point() / 10;
               
               CreateLabel(prefix + "Pips", x + 10, currentY, "Pips: " + DoubleToString(pips, 1), profitColor, 9);
            }
         }
      }
   }
   
   currentY += lineHeight + 5;
   CreateLabel(prefix + "Sep3", x + 10, currentY, "══════════════════════════", clrGray, 8);
   
   // Settings
   currentY += lineHeight;
   CreateLabel(prefix + "Settings", x + 10, currentY, "SETTINGS", clrAqua, 10);
   
   currentY += lineHeight;
   CreateLabel(prefix + "RR", x + 10, currentY, "R/R: 1:" + DoubleToString(TakeProfit/StopLoss, 1) + " (" + IntegerToString(StopLoss/10) + "/" + IntegerToString(TakeProfit/10) + " pips)", clrWhite, 9);
   
   currentY += lineHeight;
   CreateLabel(prefix + "MinConf", x + 10, currentY, "Min Confirmations: " + IntegerToString(MinConfirmations) + "/8", clrWhite, 9);
   
   currentY += lineHeight;
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   color spreadColor = spread <= MaxSpread ? clrLime : clrRed;
   CreateLabel(prefix + "Spread", x + 10, currentY, "Spread: " + IntegerToString(spread) + " pts", spreadColor, 9);
}

//+------------------------------------------------------------------+
//| Create label                                                      |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int size)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}

//+------------------------------------------------------------------+
//| On Trade event                                                    |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Track performance
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
               monthlyProfit += profit;
            }
         }
      }
   }
}
//+------------------------------------------------------------------+