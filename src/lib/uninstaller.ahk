#SingleInstance Force
#NoEnv
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

Gui Font, s10 Norm
Gui Add, Button, x465 y253 w80 h27, Continue
Gui Font, s10
Gui Add, Radio, x23 y69 w255 h21 vupdate, Update/repair
Gui Font
Gui Font, s10
Gui Add, Radio, x23 y119 w255 h21 vuninstall +Checked, Uninstall
Gui Font
Gui Font, s14 Bold, Trebuchet MS
Gui Add, Text, hWndhTxt x12 y9 w471 h26 +0x200, TweetMirror is already installed
Gui Font
Gui Font, s10
Gui Add, Text, x19 y37 w465 h18 +0x200, Choose how you want to proceed...
Gui Font
Gui Add, Text, x38 y138 w318 h23 +0x200, Removes TweetMirror from your computer
Gui Add, Text, x37 y88 w350 h23 +0x200, Reinstalls TweetMirror to replaces current version with this download

Gui Show, w559 h299, TweetMirror installer
Return

GuiEscape:
GuiClose:
    ExitApp

ButtonContinue:
	Gui Submit ; Update variables
	
	if (uninstall) {
		RunWait uninstall.bat
		MsgBox,0,TweetMirror installation, Uninstall completed!
	} else if (update) {
		Run installer.exe
	}
	
	ExitApp
