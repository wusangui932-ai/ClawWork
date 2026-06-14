# LiveBench 启动脚本 - Windows版本
# 分别启动后端和前端

# 设置项目路径
$projectRoot = Get-Location
Write-Host "🚀 启动 ClawWork 项目..." -ForegroundColor Green
Write-Host "项目路径: $projectRoot" -ForegroundColor Cyan
Write-Host ""

# 检查Python和Node.js
Write-Host "📋 检查环境..." -ForegroundColor Blue
$pythonVersion = python --version 2>&1
$nodeVersion = node --version 2>&1
Write-Host "  Python: $pythonVersion" -ForegroundColor Gray
Write-Host "  Node.js: $nodeVersion" -ForegroundColor Gray
Write-Host ""

# 创建日志目录
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

Write-Host "⏳ 安装/检查 Python 依赖..." -ForegroundColor Blue
Write-Host "  (这可能需要1-2分钟)" -ForegroundColor Gray

# 后台安装 Python 依赖（如果需要）
$requirementsPath = Join-Path $projectRoot "requirements.txt"
$pipProcess = Start-Process -FilePath "python" -ArgumentList "-m pip install -q -r $requirementsPath" `
    -RedirectStandardOutput (Join-Path $projectRoot "logs\pip.log") `
    -PassThru -NoNewWindow

Write-Host ""
Write-Host "🎨 前端:" -ForegroundColor Yellow
Write-Host "  启动前端开发服务器..." -ForegroundColor Gray
Set-Location frontend
$frontendLogPath = Join-Path (Get-Location) "..\logs\frontend.log"
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" `
    -RedirectStandardOutput $frontendLogPath `
    -RedirectStandardError $frontendLogPath `
    -PassThru -NoNewWindow
Set-Location ..
Write-Host "  前端进程 PID: $($frontendProcess.Id)" -ForegroundColor Gray
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "🔧 后端:" -ForegroundColor Yellow
Write-Host "  启动 API 服务器..." -ForegroundColor Gray

# 等待 pip 安装完成
Wait-Process -Id $pipProcess.Id -Timeout 300 -ErrorAction SilentlyContinue
Write-Host "  Python 依赖安装完成" -ForegroundColor Gray

$apiLogPath = Join-Path $projectRoot "logs\api.log"
$apiProcess = Start-Process -FilePath "python" -ArgumentList "livebench/api/server.py" `
    -RedirectStandardOutput $apiLogPath `
    -RedirectStandardError $apiLogPath `
    -PassThru -NoNewWindow
Write-Host "  API 进程 PID: $($apiProcess.Id)" -ForegroundColor Gray

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ 服务已启动！" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📍 访问地址:" -ForegroundColor Cyan
Write-Host "  前端: http://localhost:3000" -ForegroundColor Yellow
Write-Host "  API:  http://localhost:8000" -ForegroundColor Yellow
Write-Host "  文档: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "📝 日志文件:" -ForegroundColor Cyan
Write-Host "  前端: logs\frontend.log" -ForegroundColor Gray
Write-Host "  API:  logs\api.log" -ForegroundColor Gray
Write-Host ""
Write-Host "⏹️  按 Ctrl+C 停止服务" -ForegroundColor Red
Write-Host ""

# 显示实时日志摘要
Write-Host "📊 实时状态:" -ForegroundColor Cyan
while ($true) {
    $frontendRunning = Get-Process -Id $frontendProcess.Id -ErrorAction SilentlyContinue
    $apiRunning = Get-Process -Id $apiProcess.Id -ErrorAction SilentlyContinue
    
    $frontendStatus = if ($frontendRunning) { "✅ 运行中" } else { "❌ 已停止" }
    $apiStatus = if ($apiRunning) { "✅ 运行中" } else { "❌ 已停止" }
    
    Write-Host "  前端: $frontendStatus | API: $apiStatus" -ForegroundColor Gray -NoNewline
    Write-Host "`r" -NoNewline
    
    Start-Sleep -Seconds 2
}
