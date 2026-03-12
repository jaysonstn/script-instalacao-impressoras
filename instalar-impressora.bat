@echo off

:: Verifica se está rodando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Executando como administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

echo ===============================
echo INSTALADOR DE IMPRESSORA
echo ===============================
echo.

:: Criar C:\Temp se não existir
if not exist "C:\Temp" (
    echo Criando pasta C:\Temp...
    mkdir "C:\Temp"
)

:: Nome da pasta atual
set "ORIGEM=%~dp0"
set "DESTINO=C:\Temp\InstaladorImpressora"

echo Copiando arquivos para %DESTINO% ...

:: Remove pasta antiga se existir
if exist "%DESTINO%" (
    rmdir /s /q "%DESTINO%"
)

:: Copia tudo
xcopy "%ORIGEM%" "%DESTINO%\" /E /I /Y >nul

echo.
echo Arquivos copiados com sucesso.
echo.

:: Executa o script PowerShell localmente
powershell -ExecutionPolicy Bypass -File "%DESTINO%\instalar-impressora.ps1"

pause