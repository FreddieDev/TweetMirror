@echo off
cls

REM Script settings:
title Installing TweetMirror...
color 70
mode con: cols=90 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo Closing open instances of TweetMirror...
taskkill /F /IM TweetMirror.exe

IF NOT EXIST %installDir% (
	echo.
	echo Making TweetMirror folder...
	mkdir %installDir%
)

echo.
echo Installing files...
copy TweetMirror.exe %installDir%\TweetMirror.exe
copy TweetMirror.ini %installDir%\TweetMirror.ini
copy TeamsCardTemplate.json %installDir%\TeamsCardTemplate.json


echo.
echo Starting app...
start "" "%installDir%\TweetMirror.exe"

echo.
CHOICE /C YN /N /M "Would you like TweetMirror to run on startup [Y/N]? "
if %ERRORLEVEL% == 1 (
	GOTO InstallForStartup
) else if EXIST "%startupDir%\TweetMirror.lnk" (
	del "%startupDir%\TweetMirror.lnk"
)

:InstallFinished
	echo.
	echo.
	echo Done! Press any key to quit...
	pause>nul
	exit


REM Function to add shortcut file to user's startup folder
:InstallForStartup
	echo Adding to startup...
	set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"

	echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
	echo sLinkFile = "%startupDir%\TweetMirror.lnk" >> %SCRIPT%
	echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
	echo oLink.TargetPath = "%installDir%\TweetMirror.exe" >> %SCRIPT%
	echo oLink.Save >> %SCRIPT%

	cscript /nologo %SCRIPT%
	del %SCRIPT%

	GOTO InstallFinished