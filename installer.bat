@echo off
title Starting installer...
mode con: cols=90 lines=20
set "installDir=%USERPROFILE%\Documents\TweetMirror"
cls


echo Detecting install state...
IF NOT EXIST %installDir% (
	echo Running installer...
	start "" "src\lib\installer.exe"
) else (
	echo Running uninstaller...
	start "" "src\lib\uninstaller.exe"
)