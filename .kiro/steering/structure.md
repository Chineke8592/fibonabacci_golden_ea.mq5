# Project Structure

## Directory Organization
```
/
├── .kiro/                 # Kiro configuration and steering rules
│   └── steering/          # AI assistant guidance documents
├── src/                   # Source code
│   ├── analyzers/         # Multi-timeframe analysis modules
│   ├── data/              # Data collection and management
│   ├── indicators/        # Technical indicators and pip calculations
│   ├── strategies/        # Trading strategies and signals
│   └── utils/             # Utility functions and helpers
├── tests/                 # Unit and integration tests
├── data/                  # Historical and real-time data storage
│   ├── raw/               # Raw market data
│   ├── processed/         # Cleaned and processed data
│   └── backtest/          # Backtesting results
├── config/                # Configuration files
│   ├── pairs.json         # Currency pairs configuration
│   ├── timeframes.json    # Timeframe settings
│   └── api_keys.env       # API credentials (not in git)
├── notebooks/             # Jupyter notebooks for analysis
├── reports/               # Generated analysis reports
└── scripts/               # Automation and utility scripts
```

## File Naming Conventions
- Use snake_case for Python files and modules
- Currency pairs in uppercase (EURUSD, GBPJPY)
- Timeframes as M1, M5, M15, H1, H4, D1, W1, MN1
- Date formats: YYYY-MM-DD for files, timestamps for data

## Code Organization Patterns
- Separate timeframe analyzers by period (M1Analyzer, H1Analyzer, etc.)
- Keep pip calculation logic in dedicated modules
- Maintain clear separation between data collection and analysis
- Use factory patterns for creating analyzers for different pairs

## Configuration Management
- API keys and secrets in environment variables
- Trading pairs and timeframes in JSON config files
- Pip values and spread settings per broker
- Risk management parameters in separate config

## Multi-Timeframe Analysis Structure
- Each timeframe analyzer implements common interface
- Pip interval tracking: 20-30 pip movements across timeframes
- Correlation analysis between different time periods
- Signal convergence detection across multiple timeframes

## Import/Module Guidelines
- Group imports: standard library, third-party, local modules
- Use absolute imports from src/ root
- Avoid circular dependencies between analyzers
- Keep data models separate from analysis logic