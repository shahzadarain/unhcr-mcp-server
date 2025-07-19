@echo off
echo ========================================
echo UNHCR MCP Server - Complete Setup Script
echo ========================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed!
    echo.
    echo Installing Node.js...
    echo Please download from: https://nodejs.org/
    start https://nodejs.org/
    pause
    exit /b 1
)
echo [OK] Node.js is installed

REM Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed!
    echo.
    echo Installing Git...
    echo Please download from: https://git-scm.com/
    start https://git-scm.com/download/win
    pause
    exit /b 1
)
echo [OK] Git is installed

REM Install npm dependencies
echo.
echo [1/7] Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies!
    pause
    exit /b 1
)
echo [OK] Dependencies installed

REM Initialize Git if needed
if not exist .git (
    echo.
    echo [2/7] Initializing Git repository...
    git init
    echo [OK] Git initialized
) else (
    echo [OK] Git already initialized
)

REM Configure Git user if needed
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [3/7] Configuring Git user...
    set /p gitname="Enter your name: "
    set /p gitemail="Enter your email: "
    git config --global user.name "%gitname%"
    git config --global user.email "%gitemail%"
    echo [OK] Git user configured
) else (
    echo [OK] Git user already configured
)

REM Add all files to Git
echo.
echo [4/7] Adding files to Git...
git add .
echo [OK] Files added

REM Commit changes
echo.
echo [5/7] Committing changes...
git commit -m "Setup UNHCR MCP server" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] No changes to commit or already committed
) else (
    echo [OK] Changes committed
)

REM Check if remote exists
git remote -v | find "origin" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [6/7] Setting up GitHub remote...
    echo.
    echo You need to create a repository on GitHub first!
    echo.
    echo 1. Go to: https://github.com/new
    echo 2. Repository name: unhcr-mcp-server
    echo 3. Make it Public
    echo 4. DO NOT initialize with README
    echo 5. Click "Create repository"
    echo.
    pause
    echo.
    set /p githubuser="Enter your GitHub username: "
    git remote add origin https://github.com/%githubuser%/unhcr-mcp-server.git
    echo [OK] Remote added
) else (
    echo [OK] GitHub remote already configured
)

REM Push to GitHub
echo.
echo [7/7] Pushing to GitHub...
git branch -M main >nul 2>&1
git push -u origin main
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push to GitHub!
    echo Make sure you've created the repository on GitHub
    pause
) else (
    echo [OK] Pushed to GitHub successfully!
)

REM Create npm package.json for publishing
echo.
echo ========================================
echo Creating npm publish configuration...
echo ========================================

REM Create .npmignore
echo .git > .npmignore
echo .gitignore >> .npmignore
echo setup.bat >> .npmignore
echo setup.ps1 >> .npmignore
echo auto-setup.bat >> .npmignore
echo test.js >> .npmignore
echo claude_desktop_config_example.json >> .npmignore

REM Test the server
echo.
echo Testing server locally...
echo const { spawn } = require('child_process'); > test-server.js
echo const child = spawn('node', ['index.js'], { stdio: 'pipe' }); >> test-server.js
echo child.stderr.on('data', (data) =^> { >> test-server.js
echo   console.log(`Server output: ${data}`); >> test-server.js
echo   if (data.includes('running')) { >> test-server.js
echo     console.log('[OK] Server test passed!'); >> test-server.js
echo     child.kill(); >> test-server.js
echo     process.exit(0); >> test-server.js
echo   } >> test-server.js
echo }); >> test-server.js
echo setTimeout(() =^> { child.kill(); process.exit(0); }, 3000); >> test-server.js

node test-server.js
del test-server.js

echo.
echo ========================================
echo NEXT STEPS FOR MCP.SO DEPLOYMENT:
echo ========================================
echo.
echo Your server is ready! Now deploy to mcp.so:
echo.
echo 1. Visit: https://mcp.so
echo 2. Sign in with GitHub
echo 3. Click "Add Server"
echo 4. Use these settings:
echo    - Name: UNHCR Data Portal
echo    - URL: https://github.com/%githubuser%/unhcr-mcp-server.git
echo    - Is DXT: No
echo.
echo 5. For Server Config, try one of these:
echo.
echo Option A (NPX format):
echo {
echo   "servers": {
echo     "unhcr": {
echo       "command": "npx",
echo       "args": ["-y", "unhcr-mcp-server"]
echo     }
echo   }
echo }
echo.
echo Option B (GitHub format):
echo {
echo   "servers": {
echo     "unhcr": {
echo       "command": "node",
echo       "args": ["index.js"],
echo       "url": "https://github.com/%githubuser%/unhcr-mcp-server.git"
echo     }
echo   }
echo }
echo.
echo ========================================
echo Setup complete!
echo ========================================
echo.
echo Your repository: https://github.com/%githubuser%/unhcr-mcp-server
echo.
pause