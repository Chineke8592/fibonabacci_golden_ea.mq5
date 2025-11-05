@echo off
echo ========================================
echo Forex Analysis System Setup
echo ========================================

echo Checking for Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found. Please install Python first:
    echo 1. Go to https://python.org/downloads
    echo 2. Download Python 3.11.x
    echo 3. IMPORTANT: Check "Add Python to PATH" during installation
    echo 4. Restart this script after installation
    pause
    exit /b 1
)

echo Python found! Setting up environment...

echo Creating virtual environment...
python -m venv forex_env

echo Activating virtual environment...
call forex_env\Scripts\activate.bat

echo Installing required packages...
pip install pandas numpy matplotlib plotly kaleido

echo Running forex analysis...
python src/main.py

echo.
echo Analysis complete! Check the reports/ folder for generated charts.
pause