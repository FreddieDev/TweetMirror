@echo off
cls

REM Script settings:
title Uninstalling TweetMirror...
color 70
mode con: cols=90 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

REM Move up out of the lib\ directory
cd ..

REM Kill TweetMirror.exe if it's running
tasklist /FI "IMAGENAME eq TweetMirror.exe" 2>NUL | find /I /N "TweetMirror.exe">NUL
if "%ERRORLEVEL%"=="0" (
	echo.
	echo Stopping app...
	taskkill /F /IM  TweetMirror.exe
)

REM Remove from startup if installed
IF EXIST "%startupDir%\TweetMirror.lnk" (
	echo.
	echo Removing from startup...
	del "%startupDir%\TweetMirror.lnk"
)

REM Remove desktop icon if one exists
IF EXIST "%USERPROFILE%\Desktop\TweetMirror.lnk" (
	del "%USERPROFILE%\Desktop\TweetMirror.lnk"
)

REM Remove files if install dir exists
if EXIST %installDir% (
	echo.
	echo Removing TweetMirror files...
	rmdir %installDir% /S /Q
)

echo.
echo.
echo Done!
REM echo Done! Press any key to quit...
REM pause>nul