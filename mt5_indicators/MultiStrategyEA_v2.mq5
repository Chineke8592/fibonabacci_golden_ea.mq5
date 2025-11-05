//+------------------------------------------------------------------+
//|                                Multi-Strategy EA v2.0 (MQL5)    |
//|                    Combines Multiple Winning Strategies         |
//|                    Enhanced with Elliott Wave & S/R            |
//+------------------------------------------------------------------+
#property copyright "Advanced Multi-Strategy EA v2.0"
#property version   "2.00"
#property description "Multi-timeframe, S/R, Supply/Demand, Breakout, Elliott Wave"

//--- Include files
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Global objects
CTrade trade;
CPositionInfo position;
COrderInfo order;

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
input bool    UseBreakEven = true;               // Use break even
input int     BreakEvenPips = 300;               // Break even trigger (points)

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

input group "=== RISK MANAGEMENT ==="
input int     MaxTradesPerDay = 5;               // Max trades per day
input int     MaxOpenTrades = 3;                 // Max open trades
input double  MaxDailyLoss = 5.0;                // Max daily loss (%)
input double  MaxDailyProfit = 10.0;             // Daily profit target (%)

input group "=== TIME FILTER ==="
input bool    UseTimeFilter = true;              // Use time filter
input int     StartHour = 8;                     // Start hour (broker time)
input int     EndHour = 20;                      // End hour (broker time)
input bool    TradeMonday = true;                // Trade on Monday
input bool    TradeTuesday = true;               // Trade on Tuesday
input bool    TradeWednesday = true;             // Trade on Wednesday
input bool    TradeThursday = true;              // Trade on Thursday
input bool    TradeFriday = true;                // Trade on Friday

//--- Global variables
datetime lastBarTime = 0;
int tradesThisDay = 0;
datetime currentDay = 0;
double dailyProfit = 0.0;
double startingBalance = 0.0;

//--- Strategy arrays
double supportLevels[];
double resistanceLevels[];
double supplyZones[][2];
double demandZones[][2];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   startingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   currentDay = TimeCurrent();
   
   ArrayResize(supportLevels, 0);
   ArrayResize(resistanceLevels, 0);
   
   Print("Multi-Strategy EA v2.0 initialized successfully");
   Print("Symbol: ", _Symbol, " | Timeframe: ", EnumToString(_Period));
   Print("Risk per trade: ", RiskPercent, "% | Max spread: ", MaxSpread);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Multi-Strategy EA v2.0 stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   if(!IsNewBar()) return;
   
   // Update daily statistics
   UpdateDailyStats();
   
   // Check risk management
   if(!CheckRiskManagement()) return;
   
   // Check time filter
   if(!CheckTimeFilter()) return;
   
   // Check spread
   if(!CheckSpread()) return;
   
   // Manage open positions
   ManagePositions();
   
   // Check for trading signals
   CheckTradingSignals();
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                          |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   datetime today = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(today, dt);
   
   // Reset daily counters at midnight
   if(dt.day != TimeDay(currentDay))
   {
      tradesThisDay = 0;
      dailyProfit = 0.0;
      currentDay = today;
      startingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   }
   
   // Calculate daily profit
   dailyProfit = ((AccountInfoDouble(ACCOUNT_BALANCE) - startingBalance) / startingBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Check risk management rules                                      |
//+------------------------------------------------------------------+
bool CheckRiskManagement()
{
   // Check max trades per day
   if(tradesThisDay >= MaxTradesPerDay)
   {
      return false;
   }
   
   // Check max open trades
   if(CountOpenPositions() >= MaxOpenTrades)
   {
      return false;
   }
   
   // Check daily loss limit
   if(dailyProfit <= -MaxDailyLoss)
   {
      Print("Daily loss limit reached: ", dailyProfit, "%");
      return false;
   }
   
   // Check daily profit target
   if(dailyProfit >= MaxDailyProfit)
   {
      Print("Daily profit target reached: ", dailyProfit, "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check time filter                                                |
//+------------------------------------------------------------------+
bool CheckTimeFilter()
{
   if(!UseTimeFilter) return true;
   
   MqlDateTime dt;
   TimeCurrent(dt);
   
   // Check day of week
   if(dt.day_of_week == 1 && !TradeMonday) return false;
   if(dt.day_of_week == 2 && !TradeTuesday) return false;
   if(dt.day_of_week == 3 && !TradeWednesday) return false;
   if(dt.day_of_week == 4 && !TradeThursday) return false;
   if(dt.day_of_week == 5 && !TradeFriday) return false;
   
   // Check hour
   if(dt.hour < StartHour || dt.hour >= EndHour) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check spread                                                     |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > MaxSpread)
   {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
         {
            // Trailing stop
            if(UseTrailingStop)
            {
               TrailingStopLogic(position.Ticket());
            }
            
            // Break even
            if(UseBreakEven)
            {
               BreakEvenLogic(position.Ticket());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing stop logic                                              |
//+------------------------------------------------------------------+
void TrailingStopLogic(ulong ticket)
{
   if(!position.SelectByTicket(ticket)) return;
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(position.PositionType() == POSITION_TYPE_BUY)
   {
      double newSL = bid - TrailingStop * point;
      if(newSL > position.StopLoss() && newSL < bid)
      {
         trade.PositionModify(ticket, newSL, position.TakeProfit());
      }
   }
   else if(position.PositionType() == POSITION_TYPE_SELL)
   {
      double newSL = ask + TrailingStop * point;
      if((newSL < position.StopLoss() || position.StopLoss() == 0) && newSL > ask)
      {
         trade.PositionModify(ticket, newSL, position.TakeProfit());
      }
   }
}

//+------------------------------------------------------------------+
//| Break even logic                                                 |
//+------------------------------------------------------------------+
void BreakEvenLogic(ulong ticket)
{
   if(!position.SelectByTicket(ticket)) return;
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(position.PositionType() == POSITION_TYPE_BUY)
   {
      if(bid >= position.PriceOpen() + BreakEvenPips * point)
      {
         if(position.StopLoss() < position.PriceOpen())
         {
            trade.PositionModify(ticket, position.PriceOpen() + 10 * point, position.TakeProfit());
         }
      }
   }
   else if(position.PositionType() == POSITION_TYPE_SELL)
   {
      if(ask <= position.PriceOpen() - BreakEvenPips * point)
      {
         if(position.StopLoss() > position.PriceOpen() || position.StopLoss() == 0)
         {
            trade.PositionModify(ticket, position.PriceOpen() - 10 * point, position.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check trading signals                                            |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
   // Update support/resistance levels
   UpdateSupportResistance();
   
   // Update supply/demand zones
   UpdateSupplyDemand();
   
   // Get multi-timeframe trend
   int trendTF1 = GetTrend(TimeFrame1);
   int trendTF2 = GetTrend(TimeFrame2);
   int trendTF3 = GetTrend(TimeFrame3);
   
   // Check Elliott Wave (if enabled)
   int waveSignal = 0;
   if(UseElliotWave)
   {
      waveSignal = GetElliottWaveSignal();
   }
   
   // Check breakout
   int breakoutSignal = GetBreakoutSignal();
   
   // Check S/R bounce
   int srSignal = GetSRBounceSignal();
   
   // Check supply/demand
   int sdSignal = GetSupplyDemandSignal();
   
   // Combine signals
   int buySignals = 0;
   int sellSignals = 0;
   
   // Multi-timeframe alignment
   if(trendTF1 == 1 && trendTF2 == 1) buySignals++;
   if(trendTF1 == -1 && trendTF2 == -1) sellSignals++;
   if(trendTF3 == 1) buySignals++;
   if(trendTF3 == -1) sellSignals++;
   
   // Strategy signals
   if(breakoutSignal == 1) buySignals++;
   if(breakoutSignal == -1) sellSignals++;
   if(srSignal == 1) buySignals++;
   if(srSignal == -1) sellSignals++;
   if(sdSignal == 1) buySignals++;
   if(sdSignal == -1) sellSignals++;
   
   // Elliott Wave filter
   if(UseElliotWave)
   {
      if(waveSignal == 1) buySignals++;
      if(waveSignal == -1) sellSignals++;
   }
   
   // Execute trades based on signal strength
   if(buySignals >= 3 && sellSignals == 0)
   {
      OpenBuyTrade();
   }
   else if(sellSignals >= 3 && buySignals == 0)
   {
      OpenSellTrade();
   }
}

//+------------------------------------------------------------------+
//| Get trend direction for timeframe                                |
//+------------------------------------------------------------------+
int GetTrend(ENUM_TIMEFRAMES tf)
{
   double ma20 = iMA(_Symbol, tf, 20, 0, MODE_EMA, PRICE_CLOSE);
   double ma50 = iMA(_Symbol, tf, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   double ma20_val[], ma50_val[];
   ArraySetAsSeries(ma20_val, true);
   ArraySetAsSeries(ma50_val, true);
   
   if(CopyBuffer(ma20, 0, 0, 3, ma20_val) <= 0) return 0;
   if(CopyBuffer(ma50, 0, 0, 3, ma50_val) <= 0) return 0;
   
   double close = iClose(_Symbol, tf, 1);
   
   if(ma20_val[0] > ma50_val[0] && close > ma20_val[0])
      return 1;  // Uptrend
   else if(ma20_val[0] < ma50_val[0] && close < ma20_val[0])
      return -1; // Downtrend
   
   return 0; // No clear trend
}

//+------------------------------------------------------------------+
//| Update support and resistance levels                             |
//+------------------------------------------------------------------+
void UpdateSupportResistance()
{
   ArrayResize(supportLevels, 0);
   ArrayResize(resistanceLevels, 0);
   
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   if(CopyHigh(_Symbol, _Period, 0, SR_Period, highs) <= 0) return;
   if(CopyLow(_Symbol, _Period, 0, SR_Period, lows) <= 0) return;
   
   // Find resistance levels
   for(int i = 2; i < SR_Period - 2; i++)
   {
      if(highs[i] > highs[i-1] && highs[i] > highs[i-2] &&
         highs[i] > highs[i+1] && highs[i] > highs[i+2])
      {
         AddResistanceLevel(highs[i]);
      }
   }
   
   // Find support levels
   for(int i = 2; i < SR_Period - 2; i++)
   {
      if(lows[i] < lows[i-1] && lows[i] < lows[i-2] &&
         lows[i] < lows[i+1] && lows[i] < lows[i+2])
      {
         AddSupportLevel(lows[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Add resistance level                                             |
//+------------------------------------------------------------------+
void AddResistanceLevel(double level)
{
   int size = ArraySize(resistanceLevels);
   ArrayResize(resistanceLevels, size + 1);
   resistanceLevels[size] = level;
}

//+------------------------------------------------------------------+
//| Add support level                                                |
//+------------------------------------------------------------------+
void AddSupportLevel(double level)
{
   int size = ArraySize(supportLevels);
   ArrayResize(supportLevels, size + 1);
   supportLevels[size] = level;
}

//+------------------------------------------------------------------+
//| Update supply and demand zones                                   |
//+------------------------------------------------------------------+
void UpdateSupplyDemand()
{
   // Simplified supply/demand zone detection
   double highs[], lows[], close[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(close, true);
   
   if(CopyHigh(_Symbol, _Period, 0, SD_Period, highs) <= 0) return;
   if(CopyLow(_Symbol, _Period, 0, SD_Period, lows) <= 0) return;
   if(CopyClose(_Symbol, _Period, 0, SD_Period, close) <= 0) return;
   
   // Find supply zones (resistance with strong rejection)
   for(int i = 5; i < SD_Period - 5; i++)
   {
      if(highs[i] > highs[i-1] && close[i] < close[i-1])
      {
         // Potential supply zone
      }
   }
}

//+------------------------------------------------------------------+
//| Get Elliott Wave signal                                          |
//+------------------------------------------------------------------+
int GetElliottWaveSignal()
{
   // Simplified Elliott Wave detection
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   if(CopyHigh(_Symbol, _Period, 0, Wave_Period, highs) <= 0) return 0;
   if(CopyLow(_Symbol, _Period, 0, Wave_Period, lows) <= 0) return 0;
   
   // Count swing highs and lows
   int swingHighs = 0;
   int swingLows = 0;
   
   for(int i = 2; i < Wave_Period - 2; i++)
   {
      if(highs[i] > highs[i-1] && highs[i] > highs[i+1])
         swingHighs++;
      if(lows[i] < lows[i-1] && lows[i] < lows[i+1])
         swingLows++;
   }
   
   // Wave 3 or 5 detection (simplified)
   if(swingHighs >= 3 && swingLows >= 2)
      return 1;  // Potential wave 3 or 5 up
   else if(swingLows >= 3 && swingHighs >= 2)
      return -1; // Potential wave 3 or 5 down
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get breakout signal                                              |
//+------------------------------------------------------------------+
int GetBreakoutSignal()
{
   double highs[], lows[], close[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(close, true);
   
   if(CopyHigh(_Symbol, _Period, 0, Breakout_Period + 1, highs) <= 0) return 0;
   if(CopyLow(_Symbol, _Period, 0, Breakout_Period + 1, lows) <= 0) return 0;
   if(CopyClose(_Symbol, _Period, 0, 3, close) <= 0) return 0;
   
   // Find highest high and lowest low
   double highestHigh = highs[ArrayMaximum(highs, 1, Breakout_Period)];
   double lowestLow = lows[ArrayMinimum(lows, 1, Breakout_Period)];
   
   // Get ATR for volatility filter
   double atr = iATR(_Symbol, _Period, ATR_Period);
   double atr_val[];
   ArraySetAsSeries(atr_val, true);
   if(CopyBuffer(atr, 0, 0, 1, atr_val) <= 0) return 0;
   
   double threshold = atr_val[0] * Breakout_Threshold;
   
   // Check for breakout
   if(close[0] > highestHigh && (close[0] - close[1]) > threshold)
      return 1;  // Bullish breakout
   else if(close[0] < lowestLow && (close[1] - close[0]) > threshold)
      return -1; // Bearish breakout
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get S/R bounce signal                                            |
//+------------------------------------------------------------------+
int GetSRBounceSignal()
{
   double close = iClose(_Symbol, _Period, 1);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Check support bounce
   for(int i = 0; i < ArraySize(supportLevels); i++)
   {
      if(MathAbs(close - supportLevels[i]) < SR_Zone * point)
      {
         // Price near support - potential buy
         if(iClose(_Symbol, _Period, 0) > iClose(_Symbol, _Period, 1))
            return 1;
      }
   }
   
   // Check resistance bounce
   for(int i = 0; i < ArraySize(resistanceLevels); i++)
   {
      if(MathAbs(close - resistanceLevels[i]) < SR_Zone * point)
      {
         // Price near resistance - potential sell
         if(iClose(_Symbol, _Period, 0) < iClose(_Symbol, _Period, 1))
            return -1;
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get supply/demand signal                                         |
//+------------------------------------------------------------------+
int GetSupplyDemandSignal()
{
   // Simplified - check if price is in demand or supply zone
   double close = iClose(_Symbol, _Period, 1);
   double low = iLow(_Symbol, _Period, 1);
   double high = iHigh(_Symbol, _Period, 1);
   
   // This is a placeholder - full implementation would track zones
   return 0;
}

//+------------------------------------------------------------------+
//| Open buy trade                                                   |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double sl = ask - StopLoss * point;
   double tp = ask + TakeProfit * point;
   
   double lots = LotSize;
   if(UseMoneyManagement)
   {
      lots = CalculateLotSize(StopLoss);
   }
   
   if(trade.Buy(lots, _Symbol, ask, sl, tp, "Multi-Strategy Buy"))
   {
      tradesThisDay++;
      Print("BUY order opened: ", lots, " lots at ", ask);
   }
}

//+------------------------------------------------------------------+
//| Open sell trade                                                  |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double sl = bid + StopLoss * point;
   double tp = bid - TakeProfit * point;
   
   double lots = LotSize;
   if(UseMoneyManagement)
   {
      lots = CalculateLotSize(StopLoss);
   }
   
   if(trade.Sell(lots, _Symbol, bid, sl, tp, "Multi-Strategy Sell"))
   {
      tradesThisDay++;
      Print("SELL order opened: ", lots, " lots at ", bid);
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(int stopLossPoints)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (RiskPercent / 100.0);
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double moneyPerPoint = tickValue / tickSize * point;
   double lots = riskAmount / (stopLossPoints * moneyPerPoint);
   
   // Normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   
   return lots;
}
//+------------------------------------------------------------------+
