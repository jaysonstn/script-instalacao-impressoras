@echo off

net session >nul 2>&1
if %errorlevel% neq 0 (
 echo Executando como administrador...
 powershell -Command "Start-Process '%~f0' -Verb RunAs"
 exit
)

powershell -ExecutionPolicy Bypass -File "%~dp0instalar-impressora.ps1"

pause