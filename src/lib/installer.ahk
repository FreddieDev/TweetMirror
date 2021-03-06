#SingleInstance Force
#NoEnv
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

Gui Font, s10 Norm
Gui Add, Button, x465 y253 w80 h27, Install
Gui Font
Gui Add, CheckBox, x138 y107 w27 h0, CheckBox
Gui Font, s10
Gui Add, CheckBox, x23 y69 w255 h21 vDesktopShortcut, Create desktop shortcut
Gui Font
Gui Font, s10
Gui Add, CheckBox, x23 y119 w255 h21 vRunOnStartup +Checked, Run on startup
Gui Font
Gui Font, s14 Bold, Trebuchet MS
Gui Add, Text, hWndhTxt x12 y9 w471 h26 +0x200, Thanks for downloading TweetMirror!
Gui Font
Gui Font, s10
Gui Add, Link, x19 y37 w465 h18 +0x200, Review the <a href="https://github.com/FreddieDev/TweetMirror/blob/master/README.md">readme</a> for tips and help...
Gui Font
Gui Add, Text, x38 y138 w318 h23 +0x200, Automatically starts TweetMirror when you login (recommended)
Gui Add, Text, x37 y88 w263 h23 +0x200, Makes an icon to start TweetMirror from your desktop

Gui Show, w559 h299, TweetMirror installer
Return

GuiEscape:
GuiClose:
    ExitApp

ButtonInstall:
	Gui Submit ; Update variables
	
	parameters := " "
	
	if (RunOnStartup)
		parameters := parameters . "runOnStartup "
	
	if (DesktopShortcut)
		parameters := parameters . "createDesktopShortcut "
	
	RunWait install.bat %parameters%
	
	MsgBox,0,TweetMirror installation, Install completed!
	
	ExitApp
