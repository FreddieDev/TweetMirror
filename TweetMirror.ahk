#Persistent  ; Keep the script running until the user exits it.
#SingleInstance force ; Only allow one instance of this script and don't prompt on replace
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SettingsName := "TweetMirror.ini"


; Global vars (leave empty)
EmailAddress :=
EmployeeNumber :=
EmailAddressKey :=



; Cleanup tray menu items
Menu, Tray, NoStandard

; Add change settings button
MenuChangeSettingsText := "Change settings"
Menu, Tray, Add, %MenuChangeSettingsText%, MenuHandler

; Creates a separator line
Menu, Tray, Add

; Add option to reload the current script (in case changes were made)
MenuReloadScriptText := "Reload script"
Menu, Tray, Add, %MenuReloadScriptText%, MenuHandler

; Add option to exit the current script
MenuExitScriptText := "Exit script"
Menu, Tray, Add, %MenuExitScriptText%, MenuHandler

; Change the tray icon
GEAR_CHECKLIST_ICON := 110
Menu, Tray, Icon, imageres.dll, %GEAR_CHECKLIST_ICON%



; Builds an API URL to get Tweets by account, written since a given tweet (by ID)
; If no Tweet ID is provided, the URL will be setup to get the 200 most recent tweets
GetTweetsAPIURL(username, sinceTweetID) {
	local sinceTweetSetting := ""
	if (StrLen(sinceTweetID) = 0) {
		sinceTweetSetting = "&since_id=" + sinceTweetID
	}
	
	return "https://api.twitter.com/1.1/statuses/user_timeline.json?trim_user=1&include_rts=0&count=200" + "&screen_name=" + username + sinceTweetSetting
}


; Runs a get request and returns the data
ProcessGetRequest(url) {
  http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  http.Open("GET", url, false)
  http.Send(data)
  
  return % http.ResponseText
}


; FirstTimeSetup(SettingsName) {
	; InputBox, EmailAddress, PasteyShortcuts, Enter your email address,,310,150
	
	; ; Re-run setup until user settings are valid
	; while (StrLen(EmailAddress) < 3) {
		; MsgBox, Invalid email address entered!
		; FirstTimeSetup(SettingsName)
		; return
	; }

	; InputBox, EmployeeNumber, PasteyShortcuts, Enter your employee number (leave blank to disable # hotkey),,310,150
	
	; ; Write user's settings
	; IniWrite, %EmailAddress%, %SettingsName%, Details, EmailAddress
	; IniWrite, %EmployeeNumber%, %SettingsName%, Details, EmployeeNumber
	
	; ; Write default hotkeys
	; IniWrite, @, %SettingsName%, Hotkeys, PasteEmailAddress
	; IniWrite, #, %SettingsName%, Hotkeys, PasteEmployeeNumber
	
	; MsgBox, Setup complete! Double press @ to paste your email or # to paste your employee number!
; }

; ; If setting file doesn't exist run first time setup
; if (!FileExist(SettingsName)) {
	; MsgBox, Thanks for downloading my tool! To use it, you must now enter your details...
	; FirstTimeSetup(SettingsName)
; }

; ; Load settings into global variables
; IniRead, EmailAddress, %SettingsName%, Details, EmailAddress
; IniRead, EmployeeNumber, %SettingsName%, Details, EmployeeNumber
; IniRead, EmailAddressKey, %SettingsName%, Hotkeys, PasteEmailAddress
; IniRead, EmployeeNumberKey, %SettingsName%, Hotkeys, PasteEmployeeNumber



; ; Register hotkeys
; Hotkey, ~$%EmailAddressKey%, EmailAddressKeyHandler
; if (StrLen(EmployeeNumber) != 0) { ; Only register employee number if a valid string is set
	; Hotkey, ~$%EmployeeNumberKey%, EmployeeNumberKeyHandler
; }

TweetsURL := GetTweetsAPIURL("lloydjason94", "")
MyTweets := ProcessGetRequest(TweetsURL)
MsgBox, %MyTweets%

return ; Stop handlers running on script start


MenuHandler:
	if (A_ThisMenuItem = MenuReloadScriptText) {
		Reload
		return
	} else if (A_ThisMenuItem = MenuExitScriptText) {
		ExitApp
	} else if (A_ThisMenuItem = MenuChangeSettingsText) {
		; FirstTimeSetup(SettingsName)
		MsgBox, Oh dear!
	}

	return
