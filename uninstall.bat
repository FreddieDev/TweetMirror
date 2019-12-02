@echo off
cls

REM Script settings:
title Uninstalling PasteyShortcuts...
color 70
mode con: cols=50 lines=20
set "installDir=%USERPROFILE%\Documents\PasteyShortcuts"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo Stopping app...
taskkill /F /IM  PasteyShortcuts.exe

echo.
echo Removing from startup...
del "%startupDir%\PasteyShortcuts.lnk"

echo.
echo Removing PasteyShortcuts files...
rmdir %installDir% /S /Q


echo.
echo.
echo Done! Press any key to quit...
pause>nul