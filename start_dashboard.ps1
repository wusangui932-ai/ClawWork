# LiveBench Dashboard Startup Script for Windows
# This script starts both the backend API and frontend dashboard

# Colors for output
$GREEN = "`e[32m"
$BLUE = "`e[34m"
$RED = "`e[31m"
$YELLOW = "`e[33m"
$NC = "`e[0m"

Write-Host "${BLUE}🚀 Starting LiveBench Dashboard...${NC}" -ForegroundColor Blue
Write-Host ""

# Check if Python is installed
Write-Host "${BLUE}🔍 Checking Python installation...${NC}" -ForegroundColor Blue
$pythonCheck = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}❌ Python 3 is not installed or not in PATH${NC}" -ForegroundColor Red
    exit 1
}
Write-Host "${GREEN}✓ Python found: $pythonCheck${NC}" -ForegroundColor Green

# Check if Node.js is installed
Write-Host "${BLUE}🔍 Checking Node.js installation...${NC}" -ForegroundColor Blue
$nodeCheck = node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}❌ Node.js is not installed or not in PATH${NC}" -ForegroundColor Red
    exit 1
}
Write-Host "${GREEN}✓ Node.js found: $nodeCheck${NC}" -ForegroundColor Green
Write-Host ""

# Install Python dependencies
Write-Host "${BLUE}📦 Installing Python dependencies...${NC}" -ForegroundColor Blue
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}❌ Failed to install Python dependencies${NC}" -ForegroundColor Red
    exit 1
}
Write-Host "${GREEN}✓ Python dependencies installed${NC}" -ForegroundColor Green
Write-Host ""

# Check if frontend dependencies are installed
if (-not (Test-Path "frontend/node_modules")) {
    Write-Host "${BLUE}📦 Installing frontend dependencies...${NC}" -ForegroundColor Blue
    Set-Location frontend
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${RED}❌ Failed to install frontend dependencies${NC}" -ForegroundColor Red
        exit 1
    }
    Set-Location ..
    Write-Host "${GREEN}✓ Frontend dependencies installed${NC}" -ForegroundColor Green
} else {
    Write-Host "${GREEN}✓ Frontend dependencies already installed${NC}" -ForegroundColor Green
}
Write-Host ""

# Build frontend
Write-Host "${BLUE}🔨 Building frontend...${NC}" -ForegroundColor Blue
Set-Location frontend
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}❌ Frontend build failed${NC}" -ForegroundColor Red
    exit 1
}
Set-Location ..
Write-Host "${GREEN}✓ Frontend built${NC}" -ForegroundColor Green
Write-Host ""

# Create logs directory if it doesn't exist
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Function to kill process on a port
function Kill-Port {
    param([int]$Port, [string]$Name)
    
    $process = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | 
               Select-Object -First 1 -ExpandProperty OwningProcess
    
    if ($process) {
        Write-Host "${YELLOW}⚠️  Found existing $Name (PID: $process) on port $Port${NC}" -ForegroundColor Yellow
        Write-Host "${YELLOW}   Killing...${NC}" -ForegroundColor Yellow
        Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        $stillRunning = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-Host "${RED}❌ Failed to kill $Name${NC}" -ForegroundColor Red
            return $false
        } else {
            Write-Host "${GREEN}✓ Killed existing $Name${NC}" -ForegroundColor Green
        }
    } else {
        Write-Host "${GREEN}✓ No existing $Name on port $Port${NC}" -ForegroundColor Green
    }
    return $true
}

# Kill existing processes before starting
Write-Host "${BLUE}🔍 Checking for existing services...${NC}" -ForegroundColor Blue
Kill-Port 8000 "Backend API" | Out-Null
Kill-Port 3000 "Frontend" | Out-Null
Write-Host ""

# Start Backend API
Write-Host "${BLUE}🔧 Starting Backend API...${NC}" -ForegroundColor Blue
$apiLogPath = Join-Path (Get-Location) "logs\api.log"
$apiProcess = Start-Process -FilePath "python" -ArgumentList "livebench/api/server.py" `
    -RedirectStandardOutput $apiLogPath -RedirectStandardError $apiLogPath `
    -PassThru -NoNewWindow
$API_PID = $apiProcess.Id

Start-Sleep -Seconds 3

# Check if API is running
if (-not (Get-Process -Id $API_PID -ErrorAction SilentlyContinue)) {
    Write-Host "${RED}❌ Failed to start Backend API${NC}" -ForegroundColor Red
    Write-Host "Check logs\api.log for details"
    exit 1
}
Write-Host "${GREEN}✓ Backend API started (PID: $API_PID)${NC}" -ForegroundColor Green

# Start Frontend
Write-Host "${BLUE}🎨 Starting Frontend Dashboard...${NC}" -ForegroundColor Blue
Set-Location frontend
$frontendLogPath = Join-Path (Get-Location) "..\logs\frontend.log"
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" `
    -RedirectStandardOutput $frontendLogPath -RedirectStandardError $frontendLogPath `
    -PassThru -NoNewWindow
$FRONTEND_PID = $frontendProcess.Id
Set-Location ..

Start-Sleep -Seconds 3

# Check if frontend is running
if (-not (Get-Process -Id $FRONTEND_PID -ErrorAction SilentlyContinue)) {
    Write-Host "${RED}❌ Failed to start Frontend${NC}" -ForegroundColor Red
    Write-Host "Check logs\frontend.log for details"
    Stop-Process -Id $API_PID -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "${GREEN}✓ Frontend started (PID: $FRONTEND_PID)${NC}" -ForegroundColor Green
Write-Host ""

Write-Host "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" -ForegroundColor Green
Write-Host "${GREEN}🎉 LiveBench Dashboard is running!${NC}" -ForegroundColor Green
Write-Host "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" -ForegroundColor Green
Write-Host ""
Write-Host "  ${BLUE}📊 Dashboard:${NC}  http://localhost:3000" -ForegroundColor Blue
Write-Host "  ${BLUE}🔧 Backend API:${NC} http://localhost:8000" -ForegroundColor Blue
Write-Host "  ${BLUE}📚 API Docs:${NC}    http://localhost:8000/docs" -ForegroundColor Blue
Write-Host ""
Write-Host "${BLUE}📝 Logs:${NC}" -ForegroundColor Blue
Write-Host "  API:      logs\api.log"
Write-Host "  Frontend: logs\frontend.log"
Write-Host ""
Write-Host "${RED}Press Ctrl+C to stop all services${NC}" -ForegroundColor Red
Write-Host ""

# Wait for processes
while ($true) {
    if (-not (Get-Process -Id $API_PID -ErrorAction SilentlyContinue)) {
        Write-Host "${RED}Backend API process exited${NC}" -ForegroundColor Red
        break
    }
    if (-not (Get-Process -Id $FRONTEND_PID -ErrorAction SilentlyContinue)) {
        Write-Host "${RED}Frontend process exited${NC}" -ForegroundColor Red
        break
    }
    Start-Sleep -Seconds 1
}

# Cleanup
Write-Host ""
Write-Host "${BLUE}🛑 Stopping services...${NC}" -ForegroundColor Blue
Stop-Process -Id $API_PID -Force -ErrorAction SilentlyContinue
Stop-Process -Id $FRONTEND_PID -Force -ErrorAction SilentlyContinue
