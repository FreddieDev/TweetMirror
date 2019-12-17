@echo off
title TweetMirror compiler...
cls

echo Recompiling initiated

echo Killing apps...
taskkill /F /IM installer.exe
taskkill /F /IM uninstaller.exe
taskkill /F /IM TweetMirror.exe

echo.
echo Recompiling TweetMirror...
start "" "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "TweetMirror.ahk" /icon "artwork\TweetMirror.ico"

echo Recompiling installer...
start "" "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "lib\uninstaller.ahk" /icon "artwork\TweetMirror.ico"

echo Recompiling uninstaller...
start "" "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "lib\installer.ahk" /icon "artwork\TweetMirror.ico"

echo.
echo.
echo Recompile finished!
echo Press any key to exit...
pause>nul