@echo off
echo ========================================
echo Live MT5 Forex Analysis System
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "forex_env\Scripts\activate.bat" (
    echo Creating virtual environment...
    python -m venv forex_env
)

echo Activating virtual environment...
call forex_env\Scripts\activate.bat

echo.
echo Installing/Updating MetaTrader5 package...
echo Note: MT5 package requires Windows and MT5 terminal installed
pip install --upgrade MetaTrader5 2>nul
if errorlevel 1 (
    echo.
    echo ========================================
    echo MT5 Package Installation
    echo ========================================
    echo The MetaTrader5 Python package needs to be installed manually.
    echo.
    echo Please run:
    echo   pip install MetaTrader5
    echo.
    echo Or download the wheel file from:
    echo   https://pypi.org/project/MetaTrader5/
    echo ========================================
    echo.
)

echo.
echo ========================================
echo IMPORTANT: Before running
echo ========================================
echo 1. Make sure MetaTrader 5 is RUNNING
echo 2. Login to your demo account in MT5
echo 3. Enable Algo Trading in MT5:
echo    Tools ^> Options ^> Expert Advisors
echo    Check "Allow automated trading"
echo ========================================
echo.
pause

echo.
echo Starting Live MT5 Analysis...
python src/live_mt5_analysis.py

pause