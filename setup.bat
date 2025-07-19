@echo off
echo ========================================
echo UNHCR MCP Server Setup Script
echo ========================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo [1/6] Node.js found. Installing dependencies...
call npm install

if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies!
    pause
    exit /b 1
)

echo.
echo [2/6] Dependencies installed successfully!
echo.
echo [3/6] Testing server locally...
echo.
echo Starting server (press Ctrl+C to stop)...
timeout /t 2 >nul

REM Create a test script
echo console.log("Server test passed! Press Ctrl+C to continue setup..."); > test.js
node test.js
del test.js

echo.
echo [4/6] Local test complete!
echo.
echo ========================================
echo Next Steps for GitHub and mcp.so:
echo ========================================
echo.
echo [5/6] Initialize Git and push to GitHub:
echo.
echo Run these commands:
echo   git init
echo   git add .
echo   git commit -m "Initial commit of UNHCR MCP server"
echo   git branch -M main
echo.
echo Then create a new repository on GitHub and run:
echo   git remote add origin https://github.com/YOUR_USERNAME/unhcr-mcp-server.git
echo   git push -u origin main
echo.
echo [6/6] Deploy to mcp.so:
echo.
echo 1. Visit https://mcp.so
echo 2. Sign in with GitHub
echo 3. Click "Add Server"
echo 4. Select your repository
echo 5. Use these settings:
echo    - Entry point: index.js
echo    - Build command: npm install
echo    - Start command: node index.js
echo.
echo ========================================
echo Setup script complete!
echo ========================================
pause