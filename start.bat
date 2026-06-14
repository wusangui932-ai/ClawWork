@echo off
REM ClawWork Launcher - Windows Batch Script

cd /d E:\SHUJUqianyi\Wendang\GitHub\ClawWork

echo Launching ClawWork Project...
echo =======================================
echo.

REM Check if node_modules exists in frontend
if not exist "frontend\node_modules" (
    echo Installing frontend dependencies...
    cd frontend
    call npm install
    cd ..
)

echo.
echo Starting services in new windows...
echo =======================================
echo.

REM Start API server in a new window
echo Starting API server...
start "ClawWork API" cmd /k "python livebench/api/server.py"

REM Wait a bit for API to start
timeout /t 3 /nobreak

REM Start Frontend in a new window  
echo Starting Frontend (Vite dev server)...
start "ClawWork Frontend" cmd /k "cd frontend && npm run dev"

REM Wait a bit for frontend to start
timeout /t 5 /nobreak

echo.
echo =======================================
echo Launching dashboard in browser...
timeout /t 2 /nobreak
start "" http://localhost:3000

echo.
echo Services should be running:
echo   - Frontend: http://localhost:3000
echo   - API: http://localhost:8000
echo   - Docs: http://localhost:8000/docs
echo.
echo Both windows will remain open. Close them to stop the services.
pause
