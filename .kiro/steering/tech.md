# Technology Stack

## Build System & Tools
- Language: Python 3.9+
- Package manager: pip/conda
- Data analysis: pandas, numpy
- Visualization: matplotlib, plotly
- API integration: requests, websockets

## Tech Stack
- Backend: Python with asyncio for real-time data
- Data storage: SQLite/PostgreSQL for historical data
- APIs: MetaTrader 5, Alpha Vantage, or similar forex data providers
- Analysis: Technical indicators library (TA-Lib)
- Scheduling: APScheduler for automated analysis

## Development Environment
- Python virtual environment required
- Jupyter notebooks for analysis prototyping
- VS Code with Python extensions recommended

## Common Commands
```bash
# Setup environment
python -m venv forex_env
source forex_env/bin/activate  # Linux/Mac
# forex_env\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run analysis
python src/main.py

# Run tests
pytest tests/

# Start data collection
python src/data_collector.py

# Generate reports
python src/report_generator.py
```

## Dependencies
- pandas>=1.5.0 - Data manipulation
- numpy>=1.21.0 - Numerical computations
- matplotlib>=3.5.0 - Basic plotting
- plotly>=5.0.0 - Interactive charts
- requests>=2.28.0 - API calls
- websocket-client>=1.4.0 - Real-time data
- TA-Lib>=0.4.25 - Technical indicators

## Code Style & Standards
- Follow PEP 8 for Python code formatting
- Use type hints for function parameters and returns
- Docstrings for all classes and functions
- Constants in UPPER_CASE
- Class names in PascalCase, functions in snake_case