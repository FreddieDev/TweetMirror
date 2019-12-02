@echo off
cls

REM Script settings:
title Uninstalling TweetMirror...
color 70
mode con: cols=50 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo Stopping app...
taskkill /F /IM  TweetMirror.exe

echo.
echo Removing from startup...
del "%startupDir%\TweetMirror.lnk"

echo.
echo Removing TweetMirror files...
rmdir %installDir% /S /Q


echo.
echo.
echo Done! Press any key to quit...
pause>nul