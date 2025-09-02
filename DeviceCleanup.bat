@echo off
setlocal
title Limpador Full Power - by Gotao
color 0A

:: ==============================
:: SALVA O HORARIO ORIGINAL
set "horario_atual=%time%"
echo Horario atual do sistema: %horario_atual%
echo.

:: PEGA O TEMPO DE UPTIME
for /f "tokens=1" %%i in ('wmic os get lastbootuptime ^| find "."') do set "uptime=%%i"

:: CONVERTE PARA HORA LEGIVEL
set "last_boot=%uptime:~0,8% %uptime:~8,6%"
set /a uptime_seconds=((%uptime:~8,2% * 3600) + (%uptime:~10,2% * 60) + %uptime:~12,2%)

:: CALCULA O HORARIO NOVO
set /a hours=(uptime_seconds / 3600)
set /a minutes=(uptime_seconds %% 3600) / 60
set /a seconds=uptime_seconds %% 60
set "horario_novo=0%hours%:0%minutes%:0%seconds%"
echo Horario temporario ajustado: %horario_novo%

:: MUDA O HORARIO DO SISTEMA
time %horario_novo%
echo Horario alterado com sucesso!
echo.
pause

:: ==============================
:menu
cls
echo.
echo  +-----------------------------------------------------------+
echo  ^|                     MENU PRINCIPAL                       ^|
echo  +-----------------------------------------------------------+
echo  [1] Rodar Limpeza Full Power
echo  [2] Parar e desativar Servicos
echo  [3] Reiniciar Explorer
echo  [4] Limpar Downloads e Temp
echo  [0] Sair
echo  +-----------------------------------------------------------+
echo.
set /p opcao=Escolha uma opcao: 

if "%opcao%"=="1" goto opcao1
if "%opcao%"=="2" goto opcao2
if "%opcao%"=="3" goto opcao3
if "%opcao%"=="4" goto opcao4
if "%opcao%"=="0" goto fim
goto menu

:opcao1
echo =======================
echo [1/7] Limpando memoria de processos...
for %%p in (explorer.exe dwm.exe lsass.exe svchost.exe) do (
    powershell -command "& {Get-Process %%p -ErrorAction SilentlyContinue | ForEach-Object { $ws = Add-Type -MemberDefinition '[DllImport(\"psapi.dll\")] public static extern int EmptyWorkingSet(IntPtr hProcess);' -Name 'Win32' -Namespace Psapi -PassThru; $ws::EmptyWorkingSet($_.Handle) | Out-Null }}"
    echo -> Memoria limpa de %%p
)
echo =======================
echo [2/7] Reiniciando Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo =======================
echo [3/7] Apagando pasta Downloads em ProgramData...
if exist "C:\ProgramData\Microsoft\Network\Downloads" (
    rmdir /s /q "C:\ProgramData\Microsoft\Network\Downloads"
    echo -> Pasta 'Downloads' apagada!
) else (
    echo -> Pasta 'Downloads' nao existe.
)
echo =======================
echo [4/7] Limpando Lixeira, Temp e Prefetch...
rd /s /q %systemdrive%\$Recycle.bin >nul 2>&1
del /f /s /q %systemroot%\Prefetch\*.* >nul 2>&1
del /f /s /q "%temp%\*.*" >nul 2>&1
del /f /s /q "C:\Users\%username%\AppData\Local\Temp\*.*" >nul 2>&1
echo =======================
echo [5/7] Limpando Event Viewer...
for /f "tokens=*" %%a in ('wevtutil el') do (
    wevtutil cl "%%a" >nul 2>&1
)
echo -> Logs limpos (ignorando canais protegidos).
echo =======================
echo [6/7] Zerando USN Journal...
fsutil usn deletejournal /d C:
echo =======================
echo [7/7] Parando servicos especificados...
for %%s in (PcaSvc CDPSvc DPS SSDPSRV UmRdpService DiagTrack SysMain) do (
    sc stop %%s >nul 2>&1
    sc config %%s start= disabled >nul 2>&1
    echo -> Servico %%s parado e desativado.
)
echo -> Desativando EventLog (efetivo no proximo boot)...
sc config EventLog start= disabled >nul 2>&1
pause
goto menu

:opcao2
echo Parando alguns servicos extras...
sc stop DPS >nul
sc stop SysMain >nul
sc stop DiagTrack >nul
sc stop PcaSvc >nul
sc stop DusmSvc >nul
sc config DPS start= disabled >nul
sc config SysMain start= disabled >nul
sc config DiagTrack start= disabled >nul
sc config PcaSvc start= disabled >nul
sc config DusmSvc start= disabled >nul
echo -> Servicos desativados.
pause
goto menu

:opcao3
echo Reiniciando Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
pause
goto menu

:opcao4
echo Limpando Downloads do usuario e temporarios...
del /q /f "%USERPROFILE%\Downloads\*"
del /q /f "%USERPROFILE%\AppData\Local\Temp\*"
rd /s /q %systemdrive%\$Recycle.bin >nul 2>&1
echo -> Downloads, Temp e Lixeira limpos!
pause
goto menu

:fim
:: ==============================
:: RESTAURA O HORARIO ORIGINAL
echo Restaurando o horario original: %horario_atual%
time %horario_atual%
echo Horario restaurado com sucesso!
echo.
echo Pressione qualquer tecla para sair...
pause >nul
cmd /k
endlocal
exit