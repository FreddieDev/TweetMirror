#Persistent  ; Keep the script running until the user exits it.
#SingleInstance force ; Only allow one instance of this script and don't prompt on replace
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SettingsName := "TweetMirror.ini"

#Include JSON.ahk


; Global vars (leave empty)
TeamsWebhookURL :=
TwitterScreenName :=
TweetHashtag :=
LastTweetID :=
ConsumerKey :=
ConsumerSecret :=



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


FirstTimeSetup(SettingsName) {
	InputBox, TeamsWebhookURL, TweetMirror, Enter your MS Teams connector WebHook URL,,310,150,,,,,%TeamsWebhookURL%
	InputBox, TwitterScreenName, TweetMirror, Enter your Twitter username,,310,150,,,,,@
	InputBox, TweetHashtag, TweetMirror, Enter the hashtags you want to filter Tweets with,,310,150,,,,,#
	
	InputBox, ConsumerKey, TweetMirror, Enter your Twitter app's consumer key,,310,150
	InputBox, ConsumerSecret, TweetMirror, Enter your Twitter app's consumer secret,,310,150
	
	; Strip unneeded characters
	TwitterScreenName := StrReplace(TwitterScreenName, "@")
	TweetHashtag := StrReplace(TweetHashtag, "#")
	
	; Write user's settings
	IniWrite, %TeamsWebhookURL%, %SettingsName%, Settings, TeamsWebhookURL
	IniWrite, %TwitterScreenName%, %SettingsName%, Settings, TwitterScreenName
	IniWrite, %TweetHashtag%, %SettingsName%, Settings, TweetHashtag
	
	IniWrite, %ConsumerKey%, %SettingsName%, Settings, ConsumerKey
	IniWrite, %ConsumerSecret%, %SettingsName%, Settings, ConsumerSecret
	
	MsgBox, Setup complete!
}

; If setting file doesn't exist run first time setup
if (!FileExist(SettingsName)) {
	MsgBox, Thanks for downloading my tool! To use it, you must setup your details...
	FirstTimeSetup(SettingsName)
}

; Load settings into global variables
IniRead, TeamsWebhookURL, %SettingsName%, Settings, TeamsWebhookURL
IniRead, TwitterScreenName, %SettingsName%, Settings, TwitterScreenName
IniRead, TweetHashtag, %SettingsName%, Settings, TweetHashtag
IniRead, LastTweetID, %SettingsName%, Settings, LastTweetID

IniRead, ConsumerKey, %SettingsName%, Settings, ConsumerKey
IniRead, ConsumerSecret, %SettingsName%, Settings, ConsumerSecret



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



; Load teams card template JSON into object
FileRead, TeamsMsgTemplate, TeamsCardTemplate.json
; Catch file load error
if (ErrorLevel) {
    MsgBox, TeamsCardTemplate.json couldn't be read!
	ExitApp
}
TeamsMsgJSON := JSON.Load(TeamsMsgTemplate)


; Twitter user vars:
; profillePic := "https://pbs.twimg.com/profile_images/915234036771168256/eONTBzwz_normal.jpg" ; profile_image_url_https
accountName := "Jason Lloyd" ; user.name
screenName := "lloydjason94" ; user.screen_name
tweetTheme := "1DA1F2" ; profile_link_color
tweetDate := "Thu Nov 28 15:12:23 +0000 2019" ; created_at
tweetBody := "Hello world #tweetmirror" ; text


; Fill in template:
TeamsMsgJSON.title := accountName . " Tweeted:"
TeamsMsgJSON.summary := accountName . " shared a Tweet."
TeamsMsgJSON.themeColor := tweetTheme
TeamsMsgJSON.potentialAction[1].name := "Follow @" . screenName
TeamsMsgJSON.potentialAction[1].targets[1].uri := "https://twitter.com/" . screenName
TeamsMsgJSON.sections[1].facts[1].name := "Posted at:"
TeamsMsgJSON.sections[1].facts[1].value :=  tweetDate
TeamsMsgJSON.sections[1].text := tweetBody

TeamsMsgJSONStr := JSON.Dump( TeamsMsgJSON )

; Send message to teams
whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
whr.Open("POST", TeamsWebhookURL, true)
whr.SetRequestHeader("Content-Type", "application/json")
whr.Send(TeamsMsgJSONStr)
whr.WaitForResponse()

return ; Stop handlers running on script start



;https://outlook.office.com/webhook/5e951759-27a0-4219-9be4-6f46778d984d@76a2ae5a-9f00-4f6b-95ed-5d33d77c4d61/IncomingWebhook/9b25608d3ca641cc8a5316952091908c/6fd7c3cf-a28e-4d02-9ac3-a213ffbe6829

; TWEET:
; 	"text"

; "users"
; 	"screen_name"
; 	"profile_image_url_https"




MenuHandler:
	if (A_ThisMenuItem = MenuReloadScriptText) {
		Reload
		return
	} else if (A_ThisMenuItem = MenuExitScriptText) {
		ExitApp
	} else if (A_ThisMenuItem = MenuChangeSettingsText) {
		FirstTimeSetup(SettingsName)
	}

	return
