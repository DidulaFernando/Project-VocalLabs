@echo off
cd /d "%~dp0"

:: Start FastAPI backend
cd Server
start cmd /k "uvicorn main:app --reload"

:: Start Flutter frontend
cd ../Client
start cmd /k "flutter run -d chrome"

echo Both the backend and frontend have been started.
exit
