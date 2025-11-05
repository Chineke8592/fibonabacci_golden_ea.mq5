//+------------------------------------------------------------------+
//|                                         ElliottWaveAnalyzer.mq5 |
//|                                  Elliott Wave Analysis Indicator |
//|                                   Displays waves on MT5 charts   |
//+------------------------------------------------------------------+
#property copyright "Forex Analysis System"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Input parameters
input int      WaveSensitivity = 5;        // Wave detection sensitivity
input int      MinPipMovement = 20;        // Minimum pip movement
input int      MaxPipMovement = 30;        // Maximum pip movement
input bool     ShowWaveLabels = true;      // Show wave labels (1,2,3,4,5,A,B,C)
input bool     ShowTrendLines = true;      // Show trend lines
input bool     ShowPipMovements = true;    // Show 20-30 pip movements
input color    ImpulseWaveColor = clrYellow;    // Impulse wave color
input color    CorrectiveWaveColor = clrOrange; // Corrective wave color
input color    TrendUpColor = clrLime;          // Uptrend color
input color    TrendDownColor = clrRed;         // Downtrend color

//--- Global variables
struct WavePoint {
   datetime time;
   double price;
   string type;  // "high" or "low"
   int index;
};

struct Wave {
   int startIdx;
   int endIdx;
   double startPrice;
   double endPrice;
   string waveType;    // "impulse" or "correction"
   string waveNumber;  // "1", "2", "3", "4", "5", "A", "B", "C"
   string direction;   // "up" or "down"
};

WavePoint pivots[];
Wave waves[];
string objectPrefix = "EWA_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Elliott Wave Analyzer initialized");
   Print("Sensitivity: ", WaveSensitivity);
   Print("Pip Range: ", MinPipMovement, "-", MaxPipMovement);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Remove all objects created by indicator
   DeleteAllObjects();
   Print("Elliott Wave Analyzer removed");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Clear previous objects
   DeleteAllObjects();
   
   // Find pivot points (swing highs and lows)
   FindPivotPoints(time, high, low, rates_total);
   
   // Identify Elliott Waves
   IdentifyWaves();
   
   // Draw waves on chart
   if(ShowWaveLabels)
      DrawWaves(time);
   
   // Draw trend lines
   if(ShowTrendLines)
      DrawTrendLines(time);
   
   // Show pip movements
   if(ShowPipMovements)
      ShowPipMovements(time, high, low, close, rates_total);
   
   // Display analysis panel
   DisplayAnalysisPanel();
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Find pivot points (swing highs and lows)                        |
//+------------------------------------------------------------------+
void FindPivotPoints(const datetime &time[], const double &high[], const double &low[], int total)
{
   ArrayResize(pivots, 0);
   int window = WaveSensitivity;
   
   for(int i = window; i < total - window; i++)
   {
      // Check for swing high
      bool isHigh = true;
      for(int j = 1; j <= window; j++)
      {
         if(high[i] < high[i-j] || high[i] < high[i+j])
         {
            isHigh = false;
            break;
         }
      }
      
      if(isHigh)
      {
         int size = ArraySize(pivots);
         ArrayResize(pivots, size + 1);
         pivots[size].time = time[i];
         pivots[size].price = high[i];
         pivots[size].type = "high";
         pivots[size].index = i;
         continue;
      }
      
      // Check for swing low
      bool isLow = true;
      for(int j = 1; j <= window; j++)
      {
         if(low[i] > low[i-j] || low[i] > low[i+j])
         {
            isLow = false;
            break;
         }
      }
      
      if(isLow)
      {
         int size = ArraySize(pivots);
         ArrayResize(pivots, size + 1);
         pivots[size].time = time[i];
         pivots[size].price = low[i];
         pivots[size].type = "low";
         pivots[size].index = i;
      }
   }
   
   Print("Found ", ArraySize(pivots), " pivot points");
}

//+------------------------------------------------------------------+
//| Identify Elliott Wave patterns                                   |
//+------------------------------------------------------------------+
void IdentifyWaves()
{
   ArrayResize(waves, 0);
   int pivotCount = ArraySize(pivots);
   
   if(pivotCount < 3)
      return;
   
   // Identify corrective waves (ABC patterns)
   for(int i = 0; i < pivotCount - 2; i++)
   {
      // Check for alternating pattern
      if((pivots[i].type == "low" && pivots[i+1].type == "high" && pivots[i+2].type == "low") ||
         (pivots[i].type == "high" && pivots[i+1].type == "low" && pivots[i+2].type == "high"))
      {
         // Create Wave A
         int size = ArraySize(waves);
         ArrayResize(waves, size + 1);
         waves[size].startIdx = pivots[i].index;
         waves[size].endIdx = pivots[i+1].index;
         waves[size].startPrice = pivots[i].price;
         waves[size].endPrice = pivots[i+1].price;
         waves[size].waveType = "correction";
         waves[size].waveNumber = "A";
         waves[size].direction = (pivots[i+1].price > pivots[i].price) ? "up" : "down";
         
         // Create Wave B
         size = ArraySize(waves);
         ArrayResize(waves, size + 1);
         waves[size].startIdx = pivots[i+1].index;
         waves[size].endIdx = pivots[i+2].index;
         waves[size].startPrice = pivots[i+1].price;
         waves[size].endPrice = pivots[i+2].price;
         waves[size].waveType = "correction";
         waves[size].waveNumber = "B";
         waves[size].direction = (pivots[i+2].price > pivots[i+1].price) ? "up" : "down";
      }
   }
   
   Print("Identified ", ArraySize(waves), " waves");
}

//+------------------------------------------------------------------+
//| Draw waves on chart                                              |
//+------------------------------------------------------------------+
void DrawWaves(const datetime &time[])
{
   int waveCount = ArraySize(waves);
   
   for(int i = 0; i < waveCount; i++)
   {
      string objName = objectPrefix + "Wave_" + IntegerToString(i);
      
      // Get time values
      datetime startTime = time[waves[i].startIdx];
      datetime endTime = time[waves[i].endIdx];
      
      // Draw wave line
      color lineColor = (waves[i].waveType == "impulse") ? ImpulseWaveColor : CorrectiveWaveColor;
      
      ObjectCreate(0, objName, OBJ_TREND, 0, startTime, waves[i].startPrice, endTime, waves[i].endPrice);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
      
      // Draw wave label
      string labelName = objectPrefix + "Label_" + IntegerToString(i);
      datetime midTime = startTime + (endTime - startTime) / 2;
      double midPrice = (waves[i].startPrice + waves[i].endPrice) / 2;
      
      ObjectCreate(0, labelName, OBJ_TEXT, 0, midTime, midPrice);
      ObjectSetString(0, labelName, OBJPROP_TEXT, waves[i].waveNumber);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   }
}

//+------------------------------------------------------------------+
//| Draw trend lines                                                  |
//+------------------------------------------------------------------+
void DrawTrendLines(const datetime &time[])
{
   int pivotCount = ArraySize(pivots);
   
   if(pivotCount < 2)
      return;
   
   // Draw trend line through recent pivots
   for(int i = 0; i < MathMin(5, pivotCount - 1); i++)
   {
      string objName = objectPrefix + "Trend_" + IntegerToString(i);
      
      color trendColor = (pivots[i+1].price > pivots[i].price) ? TrendUpColor : TrendDownColor;
      
      ObjectCreate(0, objName, OBJ_TREND, 0, pivots[i].time, pivots[i].price, 
                   pivots[i+1].time, pivots[i+1].price);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, trendColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
   }
}

//+------------------------------------------------------------------+
//| Show pip movements in specified range                            |
//+------------------------------------------------------------------+
void ShowPipMovements(const datetime &time[], const double &high[], const double &low[], 
                      const double &close[], int total)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point * 100;
   
   int movementCount = 0;
   
   for(int i = 50; i < total - 1; i++)
   {
      for(int j = i + 1; j < MathMin(i + 50, total); j++)
      {
         double pipMove = MathAbs(close[j] - close[i]) / pipValue;
         
         if(pipMove >= MinPipMovement && pipMove <= MaxPipMovement)
         {
            string objName = objectPrefix + "Pip_" + IntegerToString(movementCount);
            
            color moveColor = (close[j] > close[i]) ? clrLime : clrRed;
            
            ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time[i], close[i], time[j], close[j]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, moveColor);
            ObjectSetInteger(0, objName, OBJPROP_FILL, false);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            
            movementCount++;
            if(movementCount >= 10) return; // Limit to 10 movements
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Display analysis panel                                            |
//+------------------------------------------------------------------+
void DisplayAnalysisPanel()
{
   string panelName = objectPrefix + "Panel";
   int x = 20;
   int y = 50;
   
   // Create background
   ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, panelName, OBJPROP_XSIZE, 250);
   ObjectSetInteger(0, panelName, OBJPROP_YSIZE, 150);
   ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, panelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panelName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
   
   // Title
   string titleName = objectPrefix + "Title";
   ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, y + 10);
   ObjectSetString(0, titleName, OBJPROP_TEXT, "Elliott Wave Analysis");
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
   
   // Wave count
   string wavesName = objectPrefix + "WaveCount";
   ObjectCreate(0, wavesName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, wavesName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, wavesName, OBJPROP_YDISTANCE, y + 35);
   ObjectSetString(0, wavesName, OBJPROP_TEXT, "Total Waves: " + IntegerToString(ArraySize(waves)));
   ObjectSetInteger(0, wavesName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, wavesName, OBJPROP_FONTSIZE, 9);
   
   // Pivot count
   string pivotsName = objectPrefix + "PivotCount";
   ObjectCreate(0, pivotsName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, pivotsName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, pivotsName, OBJPROP_YDISTANCE, y + 55);
   ObjectSetString(0, pivotsName, OBJPROP_TEXT, "Pivot Points: " + IntegerToString(ArraySize(pivots)));
   ObjectSetInteger(0, pivotsName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, pivotsName, OBJPROP_FONTSIZE, 9);
   
   // Pip range
   string pipName = objectPrefix + "PipRange";
   ObjectCreate(0, pipName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, pipName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, pipName, OBJPROP_YDISTANCE, y + 75);
   ObjectSetString(0, pipName, OBJPROP_TEXT, "Pip Range: " + IntegerToString(MinPipMovement) + "-" + IntegerToString(MaxPipMovement));
   ObjectSetInteger(0, pipName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, pipName, OBJPROP_FONTSIZE, 9);
   
   // Current price
   string priceName = objectPrefix + "Price";
   ObjectCreate(0, priceName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, priceName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, priceName, OBJPROP_YDISTANCE, y + 95);
   ObjectSetString(0, priceName, OBJPROP_TEXT, "Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));
   ObjectSetInteger(0, priceName, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, priceName, OBJPROP_FONTSIZE, 9);
   
   // Timeframe
   string tfName = objectPrefix + "Timeframe";
   ObjectCreate(0, tfName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, tfName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, tfName, OBJPROP_YDISTANCE, y + 115);
   ObjectSetString(0, tfName, OBJPROP_TEXT, "TF: " + EnumToString(Period()));
   ObjectSetInteger(0, tfName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, tfName, OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Delete all objects created by indicator                          |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   int total = ObjectsTotal(0);
   
   for(int i = total - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, objectPrefix) == 0)
      {
         ObjectDelete(0, objName);
      }
   }
}
//+------------------------------------------------------------------+