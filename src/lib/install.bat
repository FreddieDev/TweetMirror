@echo off
cls

REM Script settings:
title Installing TweetMirror...
color 70
mode con: cols=90 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

set "runOnStartup=0"
set "createDesktopShortcut=0"
FOR %%A IN (%*) DO (
	IF "%%A" == "createDesktopShortcut" (
		set "createDesktopShortcut=1"
	)
	
	IF "%%A" == "runOnStartup" (
		set "runOnStartup=1"
	)
)

REM Move up out of the lib\ directory
cd ..

REM Kill TweetMirror.exe if it's running
tasklist /FI "IMAGENAME eq TweetMirror.exe" 2>NUL | find /I /N "TweetMirror.exe">NUL
if "%ERRORLEVEL%"=="0" (
	echo.
	echo Closing open instances of TweetMirror...
	taskkill /F /IM TweetMirror.exe
)

IF NOT EXIST %installDir% (
	echo.
	echo Making TweetMirror folder...
	mkdir %installDir%
)

IF NOT EXIST %installDir%\lib (
	echo.
	echo Making TweetMirror lib folder...
	mkdir %installDir%\lib
)

echo.
echo Installing files...
copy TweetMirror.exe %installDir%\TweetMirror.exe
copy TweetMirror.ini %installDir%\TweetMirror.ini
copy lib\TeamsCardTemplate.json %installDir%\lib\TeamsCardTemplate.json

echo.
echo Starting app...
start "" "%installDir%\TweetMirror.exe"

echo.
IF %createDesktopShortcut% == 1 (
	GOTO CreateDesktopShortcut
)

:ContinueInstall

echo.
IF %runOnStartup% == 1 (
	GOTO InstallForStartup
) ELSE IF EXIST "%startupDir%\TweetMirror.lnk" (
	del "%startupDir%\TweetMirror.lnk"
)

:InstallFinished
	echo.
	echo.
	echo Done!
	REM echo Done! Press any key to quit...
	REM pause>nul
	exit /b


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
	
	
:CreateDesktopShortcut
	echo Creating desktop shortcut...
	set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"

	echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
	echo sLinkFile = "%USERPROFILE%\Desktop\TweetMirror.lnk" >> %SCRIPT%
	echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
	echo oLink.TargetPath = "%installDir%\TweetMirror.exe" >> %SCRIPT%
	echo oLink.Save >> %SCRIPT%

	cscript /nologo %SCRIPT%
	del %SCRIPT%

	GOTO ContinueInstall