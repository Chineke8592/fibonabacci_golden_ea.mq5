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