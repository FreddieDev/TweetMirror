@echo off
cls

REM Script settings:
title Installing TweetMirror...
color 70
mode con: cols=50 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo Making TweetMirror folder...
mkdir %installDir%

echo.
echo Installing files...
copy TweetMirror.exe %installDir%\TweetMirror.exe
copy TweetMirror.ini %installDir%\TweetMirror.ini

echo.
echo Adding to startup...
set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = "%startupDir%\TweetMirror.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "%installDir%\TweetMirror.exe" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%

cscript /nologo %SCRIPT%
del %SCRIPT%


echo.
echo Starting app...
start "" "%installDir%\TweetMirror.exe"

echo.
echo.
echo Done! Press any key to quit...
pause>nul