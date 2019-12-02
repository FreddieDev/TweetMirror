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
ConsumerKey :=
ConsumerSecret :=
LastTweetID :=
TwitterAccessToken :=



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
	if (sinceTweetID != error & StrLen(sinceTweetID) != 0) {
		sinceTweetSetting = &since_id=%sinceTweetID%
	}

	return "https://api.twitter.com/1.1/statuses/user_timeline.json?trim_user=false&include_rts=false&count=200" . "&screen_name=" . username . sinceTweetSetting
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

; Takes a tweet object and sends it to MS teams
MirrorTweetToTeams(TeamsWebhookURL, tweetObj) {
	
	; Load teams card template JSON into object
	FileRead, TeamsMsgTemplate, TeamsCardTemplate.json
	; Catch file load error
	if (ErrorLevel) {
		MsgBox, TeamsCardTemplate.json couldn't be read!
		ExitApp
	}
	TeamsMsgJSON := JSON.Load(TeamsMsgTemplate)

	; Fill in template:
	TeamsMsgJSON.title := tweetObj.user.name . " Tweeted:"
	TeamsMsgJSON.summary := tweetObj.user.name . " shared a Tweet."
	TeamsMsgJSON.themeColor := tweetObj.user.profile_link_color
	TeamsMsgJSON.potentialAction[1].name := "Follow @" . tweetObj.user.screen_name
	TeamsMsgJSON.potentialAction[1].targets[1].uri := "https://twitter.com/" . tweetObj.user.screen_name
	TeamsMsgJSON.sections[1].facts[1].name := "Date:"
	TeamsMsgJSON.sections[1].facts[1].value :=  tweetObj.created_at
	TeamsMsgJSON.sections[1].text := tweetObj.text
	
	; Turn JSON object to string
	TeamsMsgJSONStr := JSON.Dump( TeamsMsgJSON )

	; Send message to teams webhook
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", TeamsWebhookURL, true)
	whr.SetRequestHeader("Content-Type", "application/json")
	whr.Send(TeamsMsgJSONStr)
	whr.WaitForResponse()
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

IniRead, ConsumerKey, %SettingsName%, Settings, ConsumerKey
IniRead, ConsumerSecret, %SettingsName%, Settings, ConsumerSecret

IniRead, LastTweetID, %SettingsName%, Vars, LastTweetID
IniRead, TwitterAccessToken, %SettingsName%, Vars, TwitterAccessToken





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


; Get Twitter app (FreddieDevTweetMirror) access token if none is cached
if (TwitterAccessToken = error or StrLen(TwitterAccessToken) = 0) {
	BearerTokenCredentials := ConsumerKey . ":" . ConsumerSecret
	BearerTokenCredentialsEncoded := b64Encode(BearerTokenCredentials)
	AuthString := "Basic " . BearerTokenCredentialsEncoded

	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", "https://api.twitter.com/oauth2/token", true)
	whr.SetRequestHeader("Authorization", AuthString)
	whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
	; whr.SetRequestHeader("User-Agent", "FreddieDevTweetMirror")
	whr.Send("grant_type=client_credentials")
	whr.WaitForResponse()
	sleep 200
	msgBody := whr.ResponseText

	authJSON := JSON.Load(msgBody)
	
	TwitterAccessToken := authJSON.access_token
	IniWrite, %TwitterAccessToken%, %SettingsName%, Vars, TwitterAccessToken ; Cache
}




; Get tweets
TweetsURL := GetTweetsAPIURL("lloydjason94", LastTweetID)
MyTweetsJSON := ProcessTwitterAPICall(TwitterAccessToken, TweetsURL)
MyTweets := JSON.Load(MyTweetsJSON) ; Convert JSON to object

; Quit app if no new tweets found
if (MyTweets.Length() = 0) {
	ExitApp
}


; Process tweets
for index, tweet in MyTweets {
    if (InStr(tweet.text, TweetHashtag)) {
		MirrorTweetToTeams(TeamsWebhookURL, tweet)
	}
}

; Update last tweet ID
LastTweetID := MyTweets[1].id
IniWrite, %LastTweetID%, %SettingsName%, Vars, LastTweetID


return ; Stop handlers running on script start




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
