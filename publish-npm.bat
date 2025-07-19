@echo off
echo ========================================
echo NPM Publishing Script for UNHCR MCP Server
echo ========================================
echo.

REM Check if npm is logged in
npm whoami >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to login to npm first.
    echo.
    echo If you don't have an npm account:
    echo 1. Go to https://www.npmjs.com/signup
    echo 2. Create an account
    echo.
    echo Then run: npm login
    echo.
    pause
    exit /b 1
)

echo [OK] NPM login verified
echo.

REM Update package
echo Updating package...
git add .
git commit -m "Update package for npm publishing"
git push origin main

REM Publish to npm
echo.
echo Publishing to npm...
npm publish --access public

if %errorlevel% eq 0 (
    echo.
    echo ========================================
    echo SUCCESS! Package published to npm!
    echo ========================================
    echo.
    echo Your package is now available at:
    echo https://www.npmjs.com/package/@shahzadarain/unhcr-mcp-server
    echo.
    echo Users can now install it with:
    echo npm install -g @shahzadarain/unhcr-mcp-server
    echo.
    echo For mcp.so, use this configuration:
    echo {
    echo   "servers": {
    echo     "unhcr": {
    echo       "command": "npx",
    echo       "args": ["-y", "@shahzadarain/unhcr-mcp-server"]
    echo     }
    echo   }
    echo }
    echo.
) else (
    echo.
    echo [ERROR] Failed to publish to npm
    echo.
    echo Common issues:
    echo - Package name already exists
    echo - Not logged in to npm
    echo - Network issues
    echo.
)

pause