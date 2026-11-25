@echo off
title Seldon - Task Management ^& Client Support Ticket System
echo ========================================================
echo  Starting Seldon Development Server
echo ========================================================
echo.
echo Ensuring PostgreSQL service is active...
net start postgresql-x64-18 >nul 2>&1

echo Starting CodeIgniter 4 server at http://localhost:8080
echo Press Ctrl+C in this window to stop the server.
echo.

E:\php82\php.exe spark serve --port 8080
pause
