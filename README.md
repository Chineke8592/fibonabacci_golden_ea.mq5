# Forex Multi-Timeframe Analysis System

A Python-based system for analyzing forex currency pairs across multiple timeframes with specific pip interval tracking (20-30 pips).

## Features

- **Multi-timeframe Analysis**: Analyze M1, M5, M15, H1, H4, and D1 timeframes
- **Pip Interval Tracking**: Focus on 20-30 pip movements for entry/exit signals
- **Convergence Detection**: Find signals where multiple timeframes align
- **Configurable Pairs**: Support for major and cross currency pairs
- **Real-time Processing**: Designed for live market analysis

## Quick Start

1. **Setup Environment**
   ```bash
   python -m venv forex_env
   source forex_env/bin/activate  # Linux/Mac
   # forex_env\Scripts\activate   # Windows
   ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run Analysis**
   ```bash
   python src/main.py
   ```

## Configuration

- **Currency Pairs**: Edit `config/pairs.json` to add/remove pairs
- **Pip Intervals**: Adjust min/max pip ranges in configuration
- **Timeframes**: Configure which timeframes to analyze
- **API Keys**: Add your data provider credentials to `config/api_keys.env`

## Project Structure

```
src/
├── analyzers/          # Multi-timeframe analysis modules
├── data/              # Data collection and management  
├── indicators/        # Technical indicators and pip calculations
├── strategies/        # Trading strategies and signals
└── utils/             # Utility functions

config/                # Configuration files
data/                  # Market data storage
reports/               # Analysis reports
```

## Analysis Output

The system identifies:
- Pip movements within 20-30 pip ranges across timeframes
- Direction convergence between different time periods
- Signal strength based on movement correlation
- Entry/exit timing based on multi-timeframe alignment

## Next Steps

1. Connect to real forex data provider (MetaTrader 5, Alpha Vantage, etc.)
2. Implement additional technical indicators
3. Add backtesting capabilities
4. Create visualization dashboards
5. Implement automated signal notifications