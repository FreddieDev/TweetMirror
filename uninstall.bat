@echo off
cls

REM Script settings:
title Uninstalling TweetMirror...
color 70
mode con: cols=90 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo Stopping app...
taskkill /F /IM  TweetMirror.exe


IF EXIST "%startupDir%\TweetMirror.lnk" (
	echo.
	echo Removing from startup...
	del "%startupDir%\TweetMirror.lnk"
)

if EXIST %installDir% (
	echo.
	echo Removing TweetMirror files...
	rmdir %installDir% /S /Q
)

echo.
echo.
echo Done! Press any key to quit...
pause>nul