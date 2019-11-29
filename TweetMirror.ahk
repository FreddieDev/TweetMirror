#Persistent  ; Keep the script running until the user exits it.
#SingleInstance force ; Only allow one instance of this script and don't prompt on replace
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SettingsName := "TweetMirror.ini"

#Include JSON.ahk


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
	local sinceTweetSetting :=
	if (StrLen(sinceTweetID) != 0) {
		sinceTweetSetting = &since_id=%sinceTweetID%
	}

	return "https://api.twitter.com/1.1/statuses/user_timeline.json?trim_user=true&include_rts=false&count=200" . "&screen_name=" . username . sinceTweetSetting
}


; Runs a get request and returns the data
ProcessTwitterAPICall(authtoken, url) {
  http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  http.Open("GET", url, false)
  http.SetRequestHeader("Authorization", "Bearer " + authtoken)
  http.Send()
  
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



; Base64 helper functions
b64Encode(string) {
    VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1 
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", 0, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    VarSetCapacity(buf, size << 1, 0)
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", &buf, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    return StrReplace(StrGet(&buf), "`r`n") ; Remove all line breaks (sometimes randomly added in the middle, breaks stuff)
}
b64Decode(string) {
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", 0, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    VarSetCapacity(buf, size, 0)
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", &buf, "uint*", size, "ptr", 0, "ptr", 0))
        throw Exception("CryptStringToBinary failed", -1)
    return StrGet(&buf, size, "UTF-8")
}


; Authenticate using FreddieDevTweetMirror
ConsumerKey := "S4BCR1KqwdVJR6QuCOsF32Y0n"
ConsumerSecret := "t6ygJMK58orSbn6jVCudJ2gjDmJtMhSlVYH1kw1cptisIIDcV0"
BearerTokenCredentials := ConsumerKey . ":" . ConsumerSecret
BearerTokenCredentialsEncoded := b64Encode(BearerTokenCredentials)
AuthString := "Basic " . BearerTokenCredentialsEncoded

AuthorizationReply := "{""token_type"":""bearer"",""access_token"":""AAAAAAAAAAAAAAAAAAAAAAwqBAEAAAAAvoOYojwRfnToNnM2LjIwJd%2FEMRY%3Dw5ABRJbdjv2S88av30btX9CVijnu5Ep0Fr1qlJy7CXQe2mhIgd""}"

if (StrLen(AuthorizationReply) = 0) {
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", "https://api.twitter.com/oauth2/token", true)
	whr.SetRequestHeader("Authorization", AuthString)
	whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
	; whr.SetRequestHeader("User-Agent", "FreddieDevTweetMirror")
	whr.Send("grant_type=client_credentials")
	whr.WaitForResponse()
	sleep 200
	msgBody := whr.ResponseText
	MsgBox, %msgBody%

	AuthorizationReply = whr.ResponseText
}


authJSON := JSON.Load(AuthorizationReply)

accessToken := authJSON.access_token


; Get tweets
TweetsURL := GetTweetsAPIURL("lloydjason94", "1195419706842324992")
MyTweets := ProcessTwitterAPICall(accessToken, TweetsURL)
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
