//+------------------------------------------------------------------+
//|                                              ElliottWaveEA.mq5 |
//|                          Elliott Wave Expert Advisor with Alerts |
//|                                   Sends alerts for wave patterns |
//+------------------------------------------------------------------+
#property copyright "Forex Analysis System"
#property link      ""
#property version   "1.00"

//--- Input parameters
input int      WaveSensitivity = 5;        // Wave detection sensitivity
input int      MinPipMovement = 20;        // Minimum pip movement
input int      MaxPipMovement = 30;        // Maximum pip movement
input bool     SendAlerts = true;          // Send alerts
input bool     SendNotifications = false;  // Send push notifications
input bool     SendEmails = false;         // Send email alerts
input int      CheckInterval = 60;         // Check interval (seconds)

//--- Global variables
datetime lastCheckTime = 0;
int impulseWaveCount = 0;
int correctiveWaveCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Elliott Wave EA initialized");
   Print("Sensitivity: ", WaveSensitivity);
   Print("Pip Range: ", MinPipMovement, "-", MaxPipMovement);
   Print("Check Interval: ", CheckInterval, " seconds");
   
   lastCheckTime = TimeCurrent();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Elliott Wave EA stopped");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if enough time has passed
   datetime currentTime = TimeCurrent();
   if(currentTime - lastCheckTime < CheckInterval)
      return;
   
   lastCheckTime = currentTime;
   
   // Perform Elliott Wave analysis
   AnalyzeMarket();
}

//+------------------------------------------------------------------+
//| Analyze market for Elliott Wave patterns                        |
//+------------------------------------------------------------------+
void AnalyzeMarket()
{
   // Get recent bars
   int bars = 200;
   double high[], low[], close[];
   datetime time[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   
   if(CopyHigh(_Symbol, _Period, 0, bars, high) != bars) return;
   if(CopyLow(_Symbol, _Period, 0, bars, low) != bars) return;
   if(CopyClose(_Symbol, _Period, 0, bars, close) != bars) return;
   if(CopyTime(_Symbol, _Period, 0, bars, time) != bars) return;
   
   // Find pivot points
   int pivotCount = 0;
   double pivotPrices[];
   string pivotTypes[];
   
   ArrayResize(pivotPrices, 0);
   ArrayResize(pivotTypes, 0);
   
   for(int i = WaveSensitivity; i < bars - WaveSensitivity; i++)
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
      
      if(isHigh)
      {
         int size = ArraySize(pivotPrices);
         ArrayResize(pivotPrices, size + 1);
         ArrayResize(pivotTypes, size + 1);
         pivotPrices[size] = high[i];
         pivotTypes[size] = "high";
         pivotCount++;
         continue;
      }
      
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
      
      if(isLow)
      {
         int size = ArraySize(pivotPrices);
         ArrayResize(pivotPrices, size + 1);
         ArrayResize(pivotTypes, size + 1);
         pivotPrices[size] = low[i];
         pivotTypes[size] = "low";
         pivotCount++;
      }
   }
   
   // Count waves
   int newImpulseCount = 0;
   int newCorrectiveCount = 0;
   
   // Identify corrective waves (ABC)
   for(int i = 0; i < pivotCount - 2; i++)
   {
      if((pivotTypes[i] == "low" && pivotTypes[i+1] == "high" && pivotTypes[i+2] == "low") ||
         (pivotTypes[i] == "high" && pivotTypes[i+1] == "low" && pivotTypes[i+2] == "high"))
      {
         newCorrectiveCount += 2; // A and B waves
      }
   }
   
   // Check for pip movements
   int pipMovements = 0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point * 100;
   
   for(int i = 0; i < 50; i++)
   {
      for(int j = i + 1; j < MathMin(i + 50, bars); j++)
      {
         double pipMove = MathAbs(close[j] - close[i]) / pipValue;
         
         if(pipMove >= MinPipMovement && pipMove <= MaxPipMovement)
         {
            pipMovements++;
            break;
         }
      }
   }
   
   // Generate analysis report
   string report = GenerateReport(pivotCount, newImpulseCount, newCorrectiveCount, pipMovements);
   
   // Check for new waves and send alerts
   if(newCorrectiveCount > correctiveWaveCount)
   {
      SendAlert("New Corrective Wave Detected!", report);
   }
   
   // Update counts
   impulseWaveCount = newImpulseCount;
   correctiveWaveCount = newCorrectiveCount;
   
   // Print analysis
   Print(report);
}

//+------------------------------------------------------------------+
//| Generate analysis report                                          |
//+------------------------------------------------------------------+
string GenerateReport(int pivots, int impulse, int corrective, int pipMoves)
{
   string report = "\n========================================\n";
   report += "ELLIOTT WAVE ANALYSIS - " + _Symbol + " " + EnumToString(_Period) + "\n";
   report += "========================================\n";
   report += "Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\n";
   report += "Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "\n";
   report += "----------------------------------------\n";
   report += "Pivot Points: " + IntegerToString(pivots) + "\n";
   report += "Impulse Waves (1-5): " + IntegerToString(impulse) + "\n";
   report += "Corrective Waves (A-C): " + IntegerToString(corrective) + "\n";
   report += "Pip Movements (20-30): " + IntegerToString(pipMoves) + "\n";
   report += "----------------------------------------\n";
   
   // Determine market bias
   string bias = "NEUTRAL";
   if(corrective > 10)
      bias = "CORRECTIVE PHASE";
   else if(impulse > 5)
      bias = "IMPULSE PHASE";
   
   report += "Market Phase: " + bias + "\n";
   report += "========================================\n";
   
   return report;
}

//+------------------------------------------------------------------+
//| Send alert                                                        |
//+------------------------------------------------------------------+
void SendAlert(string title, string message)
{
   if(SendAlerts)
   {
      Alert(title + "\n" + message);
   }
   
   if(SendNotifications)
   {
      SendNotification(title + " - " + _Symbol);
   }
   
   if(SendEmails)
   {
      SendMail(title, message);
   }
}

//+------------------------------------------------------------------+
//| Timer function (optional)                                         |
//+------------------------------------------------------------------+
void OnTimer()
{
   AnalyzeMarket();
}
//+------------------------------------------------------------------+