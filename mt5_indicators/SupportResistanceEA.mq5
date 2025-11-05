//+------------------------------------------------------------------+
//|                                        SupportResistanceEA.mq5 |
//|                    Support/Resistance Trading Expert Advisor    |
//|                         Trades bounces from S/R levels          |
//+------------------------------------------------------------------+
#property copyright "Forex Analysis System"
#property link      ""
#property version   "1.00"
#property description "Identifies Support/Resistance and trades bounces"

//--- Input Parameters
input group "=== Support/Resistance Settings ==="
input int      SR_Period = 20;              // Period to scan for S/R (candles)
input int      SR_Zone = 200;               // Zone around S/R level (points)

input group "=== Trade Management ==="
input double   LotSize = 0.1;               // Lot size
input int      TakeProfit = 500;            // Take Profit (points)
input int      StopLoss = 300;              // Stop Loss (points)
input bool     UseTrailingStop = true;      // Use trailing stop
input int      TrailingStop = 200;          // Trailing stop (points)
input int      TrailingStep = 50;           // Trailing step (points)

input group "=== Risk Management ==="
input int      MaxTrades = 1;               // Maximum open trades
input double   MaxRiskPercent = 2.0;        // Max risk per trade (%)
input bool     UseMoneyManagement = false;  // Auto calculate lot size

input group "=== Alert Settings ==="
input bool     SendAlerts = true;           // Send pop-up alerts
input bool     SendNotifications = false;   // Send push notifications
input bool     SendEmails = false;          // Send email alerts

input group "=== Display Settings ==="
input bool     ShowSRLines = true;          // Show S/R lines on chart
input bool     ShowZones = true;            // Show S/R zones
input bool     ShowInfoPanel = true;        // Show info panel
input color    SupportColor = clrLime;      // Support line color
input color    ResistanceColor = clrRed;    // Resistance line color

//--- Global Variables
double supportLevel = 0;
double resistanceLevel = 0;
double supportZoneHigh = 0;
double supportZoneLow = 0;
double resistanceZoneHigh = 0;
double resistanceZoneLow = 0;

datetime lastBarTime = 0;
int magicNumber = 123456;
string prefix = "SR_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("===========================================");
   Print("Support/Resistance EA Initialized");
   Print("===========================================");
   Print("SR Period: ", SR_Period, " candles");
   Print("SR Zone: ", SR_Zone, " points");
   Print("Lot Size: ", LotSize);
   Print("Take Profit: ", TakeProfit, " points");
   Print("Stop Loss: ", StopLoss, " points");
   Print("===========================================");
   
   // Validate inputs
   if(SR_Period < 5)
   {
      Print("ERROR: SR_Period must be at least 5");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(SR_Zone < 50)
   {
      Print("ERROR: SR_Zone must be at least 50 points");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   // Initial S/R calculation
   IdentifySupportResistance();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up chart objects
   DeleteAllObjects();
   Print("Support/Resistance EA stopped");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   bool isNewBar = (currentBarTime != lastBarTime);
   
   if(isNewBar)
   {
      lastBarTime = currentBarTime;
      
      // Phase 1: Identification - Scan for Support/Resistance
      IdentifySupportResistance();
      
      // Update visual display
      if(ShowSRLines || ShowZones)
         DrawSupportResistance();
      
      if(ShowInfoPanel)
         DisplayInfoPanel();
      
      // Phase 2: Signal Generation - Check for trade signals
      CheckForTradeSignals();
   }
   
   // Manage open positions
   ManageOpenTrades();
}

//+------------------------------------------------------------------+
//| Phase 1: Identify Support and Resistance Levels                 |
//+------------------------------------------------------------------+
void IdentifySupportResistance()
{
   // Get data for last SR_Period candles
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyHigh(_Symbol, _Period, 0, SR_Period, high) != SR_Period) return;
   if(CopyLow(_Symbol, _Period, 0, SR_Period, low) != SR_Period) return;
   
   // Find Highest High = Resistance
   resistanceLevel = high[ArrayMaximum(high, 0, SR_Period)];
   
   // Find Lowest Low = Support
   supportLevel = low[ArrayMinimum(low, 0, SR_Period)];
   
   // Calculate zones (200 points around each level)
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double zoneSize = SR_Zone * point;
   
   // Support Zone
   supportZoneHigh = supportLevel + zoneSize;
   supportZoneLow = supportLevel - zoneSize;
   
   // Resistance Zone
   resistanceZoneHigh = resistanceLevel + zoneSize;
   resistanceZoneLow = resistanceLevel - zoneSize;
   
   // Log levels
   static datetime lastLog = 0;
   if(TimeCurrent() - lastLog > 3600) // Log every hour
   {
      Print("--- Support/Resistance Levels ---");
      Print("Resistance: ", DoubleToString(resistanceLevel, _Digits));
      Print("Support: ", DoubleToString(supportLevel, _Digits));
      Print("Zone Size: ", SR_Zone, " points");
      lastLog = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Phase 2: Check for Trade Signals                                |
//+------------------------------------------------------------------+
void CheckForTradeSignals()
{
   // Don't trade if max trades reached
   if(CountOpenTrades() >= MaxTrades)
      return;
   
   // Get current and previous candle data
   double close[], open[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if(CopyClose(_Symbol, _Period, 0, 3, close) != 3) return;
   if(CopyOpen(_Symbol, _Period, 0, 3, open) != 3) return;
   
   double currentPrice = close[0];
   
   // Previous candle (index 1)
   bool prevBearish = (close[1] < open[1]);  // Sellers pushing down
   bool prevBullish = (close[1] > open[1]);  // Buyers pushing up
   
   // Current candle (index 0)
   bool currBearish = (close[0] < open[0]);  // Sellers taking control
   bool currBullish = (close[0] > open[0]);  // Buyers taking control
   
   // Check BUY Signal at Support
   if(CheckBuySignal(currentPrice, prevBearish, currBullish))
   {
      string signal = "BUY SIGNAL DETECTED!\n";
      signal += "Price at Support: " + DoubleToString(currentPrice, _Digits) + "\n";
      signal += "Support Level: " + DoubleToString(supportLevel, _Digits) + "\n";
      signal += "Previous candle: Bearish (sellers pushing)\n";
      signal += "Current candle: Bullish (buyers defending)\n";
      signal += "Action: Buyers defending support level";
      
      Print(signal);
      SendAlert("BUY Signal", signal);
      
      // Open BUY trade
      OpenBuyTrade();
   }
   
   // Check SELL Signal at Resistance
   if(CheckSellSignal(currentPrice, prevBullish, currBearish))
   {
      string signal = "SELL SIGNAL DETECTED!\n";
      signal += "Price at Resistance: " + DoubleToString(currentPrice, _Digits) + "\n";
      signal += "Resistance Level: " + DoubleToString(resistanceLevel, _Digits) + "\n";
      signal += "Previous candle: Bullish (buyers pushing)\n";
      signal += "Current candle: Bearish (sellers defending)\n";
      signal += "Action: Sellers defending resistance level";
      
      Print(signal);
      SendAlert("SELL Signal", signal);
      
      // Open SELL trade
      OpenSellTrade();
   }
}

//+------------------------------------------------------------------+
//| Check BUY Signal Conditions                                      |
//+------------------------------------------------------------------+
bool CheckBuySignal(double price, bool prevBearish, bool currBullish)
{
   // BUY Signal Requirements:
   // ✓ Price approaches support zone
   // ✓ Previous candle was bearish (sellers pushing down)
   // ✓ Current candle is bullish (buyers taking control)
   // ✓ Price within SR_Zone distance from support
   
   bool inSupportZone = (price >= supportZoneLow && price <= supportZoneHigh);
   
   if(inSupportZone && prevBearish && currBullish)
   {
      Print("✓ BUY conditions met:");
      Print("  ✓ Price in support zone: ", DoubleToString(price, _Digits));
      Print("  ✓ Previous candle: Bearish");
      Print("  ✓ Current candle: Bullish");
      Print("  → Buyers defending support!");
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check SELL Signal Conditions                                     |
//+------------------------------------------------------------------+
bool CheckSellSignal(double price, bool prevBullish, bool currBearish)
{
   // SELL Signal Requirements:
   // ✓ Price approaches resistance zone
   // ✓ Previous candle was bullish (buyers pushing up)
   // ✓ Current candle is bearish (sellers taking control)
   // ✓ Price within SR_Zone distance from resistance
   
   bool inResistanceZone = (price >= resistanceZoneLow && price <= resistanceZoneHigh);
   
   if(inResistanceZone && prevBullish && currBearish)
   {
      Print("✓ SELL conditions met:");
      Print("  ✓ Price in resistance zone: ", DoubleToString(price, _Digits));
      Print("  ✓ Previous candle: Bullish");
      Print("  ✓ Current candle: Bearish");
      Print("  → Sellers defending resistance!");
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Open BUY Trade                                                    |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Calculate lot size
   double lots = LotSize;
   if(UseMoneyManagement)
      lots = CalculateLotSize(StopLoss);
   
   // Calculate SL and TP
   double sl = ask - (StopLoss * point);
   double tp = ask + (TakeProfit * point);
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   // Open trade
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = magicNumber;
   request.comment = "SR Buy @ Support";
   
   if(OrderSend(request, result))
   {
      Print("✅ BUY order opened successfully!");
      Print("   Ticket: ", result.order);
      Print("   Price: ", ask);
      Print("   SL: ", sl);
      Print("   TP: ", tp);
      Print("   Lots: ", lots);
   }
   else
   {
      Print("❌ BUY order failed! Error: ", GetLastError());
      Print("   Return code: ", result.retcode);
   }
}

//+------------------------------------------------------------------+
//| Open SELL Trade                                                   |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Calculate lot size
   double lots = LotSize;
   if(UseMoneyManagement)
      lots = CalculateLotSize(StopLoss);
   
   // Calculate SL and TP
   double sl = bid + (StopLoss * point);
   double tp = bid - (TakeProfit * point);
   
   // Normalize prices
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   // Open trade
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = magicNumber;
   request.comment = "SR Sell @ Resistance";
   
   if(OrderSend(request, result))
   {
      Print("✅ SELL order opened successfully!");
      Print("   Ticket: ", result.order);
      Print("   Price: ", bid);
      Print("   SL: ", sl);
      Print("   TP: ", tp);
      Print("   Lots: ", lots);
   }
   else
   {
      Print("❌ SELL order failed! Error: ", GetLastError());
      Print("   Return code: ", result.retcode);
   }
}

//+------------------------------------------------------------------+
//| Manage Open Trades (Trailing Stop)                              |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   if(!UseTrailingStop)
      return;
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
      
      double positionProfit = PositionGetDouble(POSITION_PROFIT);
      double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      if(type == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double newSL = bid - (TrailingStop * point);
         
         if(newSL > currentSL + (TrailingStep * point) && newSL < bid)
         {
            ModifyPosition(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double newSL = ask + (TrailingStop * point);
         
         if((newSL < currentSL - (TrailingStep * point) || currentSL == 0) && newSL > ask)
         {
            ModifyPosition(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Modify Position                                                   |
//+------------------------------------------------------------------+
bool ModifyPosition(ulong ticket, double sl, double tp)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.sl = NormalizeDouble(sl, _Digits);
   request.tp = NormalizeDouble(tp, _Digits);
   
   return OrderSend(request, result);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                |
//+------------------------------------------------------------------+
double CalculateLotSize(int stopLossPoints)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (MaxRiskPercent / 100.0);
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   double moneyPerPoint = tickValue / tickSize;
   double lots = riskAmount / (stopLossPoints * point * moneyPerPoint);
   
   // Normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   
   return lots;
}

//+------------------------------------------------------------------+
//| Count Open Trades                                                |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == magicNumber)
      {
         count++;
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Draw Support and Resistance on Chart                            |
//+------------------------------------------------------------------+
void DrawSupportResistance()
{
   // Delete old objects
   ObjectDelete(0, prefix + "Support");
   ObjectDelete(0, prefix + "Resistance");
   ObjectDelete(0, prefix + "SupportZone");
   ObjectDelete(0, prefix + "ResistanceZone");
   
   if(ShowSRLines)
   {
      // Draw Support Line
      ObjectCreate(0, prefix + "Support", OBJ_HLINE, 0, 0, supportLevel);
      ObjectSetInteger(0, prefix + "Support", OBJPROP_COLOR, SupportColor);
      ObjectSetInteger(0, prefix + "Support", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, prefix + "Support", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetString(0, prefix + "Support", OBJPROP_TEXT, "Support: " + DoubleToString(supportLevel, _Digits));
      
      // Draw Resistance Line
      ObjectCreate(0, prefix + "Resistance", OBJ_HLINE, 0, 0, resistanceLevel);
      ObjectSetInteger(0, prefix + "Resistance", OBJPROP_COLOR, ResistanceColor);
      ObjectSetInteger(0, prefix + "Resistance", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, prefix + "Resistance", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetString(0, prefix + "Resistance", OBJPROP_TEXT, "Resistance: " + DoubleToString(resistanceLevel, _Digits));
   }
   
   if(ShowZones)
   {
      datetime time1 = iTime(_Symbol, _Period, SR_Period);
      datetime time2 = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period) * 10;
      
      // Draw Support Zone
      ObjectCreate(0, prefix + "SupportZone", OBJ_RECTANGLE, 0, time1, supportZoneLow, time2, supportZoneHigh);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_COLOR, SupportColor);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_FILL, true);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_BACK, true);
      ObjectSetInteger(0, prefix + "SupportZone", OBJPROP_WIDTH, 0);
      
      // Draw Resistance Zone
      ObjectCreate(0, prefix + "ResistanceZone", OBJ_RECTANGLE, 0, time1, resistanceZoneLow, time2, resistanceZoneHigh);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_COLOR, ResistanceColor);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_FILL, true);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_BACK, true);
      ObjectSetInteger(0, prefix + "ResistanceZone", OBJPROP_WIDTH, 0);
   }
}

//+------------------------------------------------------------------+
//| Display Info Panel                                               |
//+------------------------------------------------------------------+
void DisplayInfoPanel()
{
   int x = 20;
   int y = 50;
   
   // Background
   ObjectCreate(0, prefix + "Panel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_XSIZE, 280);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_YSIZE, 180);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefix + "Panel", OBJPROP_COLOR, clrWhite);
   
   // Title
   CreateLabel(prefix + "Title", x + 10, y + 10, "S/R Trading EA", clrYellow, 10);
   
   // Info
   CreateLabel(prefix + "Resistance", x + 10, y + 35, "Resistance: " + DoubleToString(resistanceLevel, _Digits), ResistanceColor, 9);
   CreateLabel(prefix + "Support", x + 10, y + 55, "Support: " + DoubleToString(supportLevel, _Digits), SupportColor, 9);
   CreateLabel(prefix + "Zone", x + 10, y + 75, "Zone: " + IntegerToString(SR_Zone) + " points", clrWhite, 9);
   CreateLabel(prefix + "Period", x + 10, y + 95, "Period: " + IntegerToString(SR_Period) + " candles", clrWhite, 9);
   
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   CreateLabel(prefix + "Price", x + 10, y + 115, "Price: " + DoubleToString(currentPrice, _Digits), clrLime, 9);
   
   int openTrades = CountOpenTrades();
   CreateLabel(prefix + "Trades", x + 10, y + 135, "Open Trades: " + IntegerToString(openTrades), clrWhite, 9);
   
   double profit = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
         profit += PositionGetDouble(POSITION_PROFIT);
   }
   color profitColor = (profit >= 0) ? clrLime : clrRed;
   CreateLabel(prefix + "Profit", x + 10, y + 155, "Profit: $" + DoubleToString(profit, 2), profitColor, 9);
}

//+------------------------------------------------------------------+
//| Create Label Helper                                              |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int size)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}

//+------------------------------------------------------------------+
//| Send Alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string title, string message)
{
   if(SendAlerts)
      Alert(title + "\n" + message);
   
   if(SendNotifications)
      SendNotification(title + " - " + _Symbol);
   
   if(SendEmails)
      SendMail(title, message);
}

//+------------------------------------------------------------------+
//| Delete All Objects                                               |
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