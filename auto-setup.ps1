# UNHCR MCP Server - Automated Setup Script
# This script handles everything automatically

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "UNHCR MCP Server - Automated Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Function to check if command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "[✓] Node.js $nodeVersion installed" -ForegroundColor Green
} else {
    Write-Host "[✗] Node.js not found. Installing..." -ForegroundColor Red
    Start-Process "https://nodejs.org/"
    Write-Host "Please install Node.js and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Git
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "[✓] $gitVersion installed" -ForegroundColor Green
} else {
    Write-Host "[✗] Git not found. Installing..." -ForegroundColor Red
    Start-Process "https://git-scm.com/download/win"
    Write-Host "Please install Git and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Install dependencies
Write-Host "`n[1/8] Installing npm dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "[✗] Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Git initialization
if (!(Test-Path ".git")) {
    Write-Host "`n[2/8] Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "[✓] Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "[✓] Git repository already initialized" -ForegroundColor Green
}

# Configure Git user
$gitUser = git config user.name 2>$null
if (!$gitUser) {
    Write-Host "`n[3/8] Configuring Git user..." -ForegroundColor Yellow
    $userName = Read-Host "Enter your full name"
    $userEmail = Read-Host "Enter your email"
    git config --global user.name "$userName"
    git config --global user.email "$userEmail"
    Write-Host "[✓] Git user configured" -ForegroundColor Green
} else {
    Write-Host "[✓] Git user already configured: $gitUser" -ForegroundColor Green
}

# Add files to Git
Write-Host "`n[4/8] Adding files to Git..." -ForegroundColor Yellow
git add .
Write-Host "[✓] Files staged for commit" -ForegroundColor Green

# Commit changes
Write-Host "`n[5/8] Committing changes..." -ForegroundColor Yellow
$commitResult = git commit -m "Setup UNHCR MCP server" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Changes committed" -ForegroundColor Green
} else {
    Write-Host "[ℹ] No changes to commit" -ForegroundColor Yellow
}

# GitHub setup
$remoteUrl = git remote get-url origin 2>$null
if (!$remoteUrl) {
    Write-Host "`n[6/8] Setting up GitHub repository..." -ForegroundColor Yellow
    Write-Host "`nYou need to create a repository on GitHub:" -ForegroundColor Cyan
    Write-Host "1. Open: " -NoNewline
    Write-Host "https://github.com/new" -ForegroundColor Blue
    Write-Host "2. Repository name: " -NoNewline
    Write-Host "unhcr-mcp-server" -ForegroundColor Blue
    Write-Host "3. Make it " -NoNewline
    Write-Host "Public" -ForegroundColor Blue
    Write-Host "4. " -NoNewline
    Write-Host "DO NOT" -ForegroundColor Red -NoNewline
    Write-Host " initialize with README"
    Write-Host "5. Click 'Create repository'"
    Write-Host ""
    
    # Open GitHub in browser
    $openGitHub = Read-Host "Open GitHub now? (y/n)"
    if ($openGitHub -eq 'y') {
        Start-Process "https://github.com/new"
    }
    
    Write-Host ""
    Read-Host "Press Enter when you've created the repository"
    
    $githubUsername = Read-Host "`nEnter your GitHub username"
    $repoUrl = "https://github.com/$githubUsername/unhcr-mcp-server.git"
    
    git remote add origin $repoUrl
    Write-Host "[✓] GitHub remote added: $repoUrl" -ForegroundColor Green
} else {
    Write-Host "[✓] GitHub remote already configured: $remoteUrl" -ForegroundColor Green
    # Extract username from URL
    if ($remoteUrl -match "github\.com/([^/]+)/") {
        $githubUsername = $matches[1]
    }
}

# Push to GitHub
Write-Host "`n[7/8] Pushing to GitHub..." -ForegroundColor Yellow
git branch -M main 2>$null
$pushResult = git push -u origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Successfully pushed to GitHub!" -ForegroundColor Green
} else {
    Write-Host "[✗] Failed to push to GitHub" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor Yellow
    Write-Host "`nMake sure you created the repository on GitHub" -ForegroundColor Yellow
}

# Test server
Write-Host "`n[8/8] Testing server locally..." -ForegroundColor Yellow
$testScript = @'
const { spawn } = require('child_process');
const server = spawn('node', ['index.js'], { stdio: 'pipe' });
let output = '';

server.stderr.on('data', (data) => {
    output += data.toString();
    if (output.includes('running')) {
        console.log('[✓] Server test passed!');
        server.kill();
        process.exit(0);
    }
});

server.on('error', (err) => {
    console.error('[✗] Server test failed:', err.message);
    process.exit(1);
});

setTimeout(() => {
    console.log('[✗] Server test timeout');
    server.kill();
    process.exit(1);
}, 5000);
'@

$testScript | Out-File -FilePath "test-server.js" -Encoding UTF8
node test-server.js
Remove-Item "test-server.js"

# Create .npmignore
Write-Host "`nCreating .npmignore..." -ForegroundColor Yellow
@"
.git
.gitignore
*.bat
*.ps1
test*.js
claude_desktop_config*.json
Dockerfile
"@ | Out-File -FilePath ".npmignore" -Encoding UTF8

# Generate mcp.so configurations
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MCP.SO DEPLOYMENT CONFIGURATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$config1 = @"
{
  "servers": {
    "unhcr": {
      "command": "node",
      "args": ["index.js"],
      "url": "https://github.com/$githubUsername/unhcr-mcp-server.git"
    }
  }
}
"@

$config2 = @"
{
  "servers": {
    "unhcr": {
      "command": "npx",
      "args": ["-y", "@$githubUsername/unhcr-mcp-server"]
    }
  }
}
"@

Write-Host "`nSaved configurations to mcp-configs.txt" -ForegroundColor Yellow
@"
MCP.SO DEPLOYMENT CONFIGURATIONS
================================

Option 1 - Direct Node.js:
$config1

Option 2 - NPX Format:
$config2

Deployment Steps:
1. Go to: https://mcp.so
2. Sign in with GitHub
3. Click "Add Server"
4. Name: UNHCR Data Portal
5. URL: https://github.com/$githubUsername/unhcr-mcp-server.git
6. Is DXT: No
7. Use one of the configurations above
"@ | Out-File -FilePath "mcp-configs.txt" -Encoding UTF8

# Final summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your repository: " -NoNewline
Write-Host "https://github.com/$githubUsername/unhcr-mcp-server" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open " -NoNewline
Write-Host "mcp-configs.txt" -ForegroundColor Blue -NoNewline
Write-Host " for deployment configurations"
Write-Host "2. Go to " -NoNewline
Write-Host "https://mcp.so" -ForegroundColor Blue -NoNewline
Write-Host " to deploy your server"
Write-Host ""

# Open mcp.so in browser
$openMcp = Read-Host "Open mcp.so now? (y/n)"
if ($openMcp -eq 'y') {
    Start-Process "https://mcp.so"
    Start-Process "notepad" "mcp-configs.txt"
}

Read-Host "`nPress Enter to exit"