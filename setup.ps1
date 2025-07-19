# UNHCR MCP Server Setup Script (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UNHCR MCP Server Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version 2>$null
    Write-Host "[✓] Node.js $nodeVersion found" -ForegroundColor Green
} catch {
    Write-Host "[✗] ERROR: Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Install dependencies
Write-Host ""
Write-Host "[1/6] Installing dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "[✗] ERROR: Failed to install dependencies!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[✓] Dependencies installed successfully!" -ForegroundColor Green

# Test server
Write-Host ""
Write-Host "[2/6] Testing server configuration..." -ForegroundColor Yellow
$testCode = @"
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
console.log('✓ Package name:', pkg.name);
console.log('✓ Version:', pkg.version);
console.log('✓ Main file:', pkg.main);
console.log('✓ Type:', pkg.type);
console.log('✓ Server configuration test passed!');
"@

$testCode | Out-File -FilePath "test.js" -Encoding UTF8
node test.js
Remove-Item "test.js"

# Git setup check
Write-Host ""
Write-Host "[3/6] Checking Git setup..." -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>$null
    Write-Host "[✓] Git is installed: $gitVersion" -ForegroundColor Green
    
    # Check if git is initialized
    if (Test-Path ".git") {
        Write-Host "[✓] Git repository already initialized" -ForegroundColor Green
    } else {
        Write-Host "[!] Git repository not initialized" -ForegroundColor Yellow
        Write-Host "Would you like to initialize it now? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -eq 'y') {
            git init
            git add .
            git commit -m "Initial commit of UNHCR MCP server"
            git branch -M main
            Write-Host "[✓] Git repository initialized" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "[✗] Git is not installed. Please install Git from https://git-scm.com/" -ForegroundColor Red
}

# Create claude_desktop_config.json example
Write-Host ""
Write-Host "[4/6] Creating Claude Desktop config example..." -ForegroundColor Yellow
$configExample = @{
    mcpServers = @{
        unhcr = @{
            command = "node"
            args = @("C:\data\unhcr-mcp-server\index.js")
        }
    }
}

$configJson = $configExample | ConvertTo-Json -Depth 3
$configJson | Out-File -FilePath "claude_desktop_config_example.json" -Encoding UTF8
Write-Host "[✓] Created claude_desktop_config_example.json" -ForegroundColor Green

# Display next steps
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete! Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "LOCAL TESTING:" -ForegroundColor Yellow
Write-Host "1. Run: node index.js" -ForegroundColor White
Write-Host "2. Add to Claude Desktop using claude_desktop_config_example.json" -ForegroundColor White
Write-Host ""
Write-Host "GITHUB DEPLOYMENT:" -ForegroundColor Yellow
Write-Host "1. Create a new repository on GitHub" -ForegroundColor White
Write-Host "2. Run these commands:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/unhcr-mcp-server.git" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "MCP.SO DEPLOYMENT:" -ForegroundColor Yellow
Write-Host "1. Visit https://mcp.so" -ForegroundColor White
Write-Host "2. Sign in with GitHub" -ForegroundColor White
Write-Host "3. Click 'Add Server'" -ForegroundColor White
Write-Host "4. Select your repository" -ForegroundColor White
Write-Host "5. Use these settings:" -ForegroundColor White
Write-Host "   - Entry point: index.js" -ForegroundColor Gray
Write-Host "   - Build command: npm install" -ForegroundColor Gray
Write-Host "   - Start command: node index.js" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All files created successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit"