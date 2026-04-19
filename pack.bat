@echo off
set SCRIPT_PATH=%~dp0pack.ps1

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" %* || pause
