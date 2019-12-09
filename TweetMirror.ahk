#Persistent  ; Keep the script running until the user exits it.
#SingleInstance force ; Only allow one instance of this script and don't prompt on replace
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SettingsName := "TweetMirror.ini"

#Include lib\lib.ahk
#Include lib\JSON.ahk
#Include lib\MetaFromURL.ahk

; Global vars (leave empty)
TeamsWebhookURL :=
TwitterScreenName :=
TweetHashtag :=
ConsumerKey :=
ConsumerSecret :=
LastTweetID :=
TwitterAccessToken :=

; Global vars (hard-coded settings)
PollRate := 30000 ; How frequently to check for new tweets
MaxSearchedTweets := 20 ; The maximum amount of Tweets to look through
ERROR_ICON := 78
LOADING_ICON := 239
DEFAULT_ICON := StrReplace(A_ScriptFullPath, ".ahk", ".exe")
NextPoll := A_TickCount




; Cleanup tray menu items
Menu, Tray, Tip, TweetMirror
Menu, Tray, Icon, %DEFAULT_ICON%
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



; Builds an API URL to get Tweets by account, written since a given tweet (by ID)
; If no Tweet ID is provided, the URL will be setup to get the 200 most recent tweets
GetTweetsAPIURL(username, sinceTweetID) {
	local sinceTweetSetting :=
	if (sinceTweetID != "ERROR" and StrLen(sinceTweetID) != 0) {
		sinceTweetSetting = &since_id=%sinceTweetID%
	}
	
	apiUrl := "https://api.twitter.com/1.1/statuses/user_timeline.json"
	return apiUrl . "?trim_user=false&include_rts=false&tweet_mode=extended" . "&screen_name=" . username . "&count=" . MaxSearchedTweets . sinceTweetSetting
}


; Runs a get request and returns the data
ProcessTwitterAPICall(authtoken, url) {
	try {
		http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.Open("GET", url, false)
		http.SetRequestHeader("Authorization", "Bearer " + authtoken)
		http.Send()
	} catch e {
		Menu, Tray, Tip, TweetMirror error: %e%
		return false
	}
  
  return % http.ResponseText
}


FirstTimeSetup(SettingsName, hasFallbackSettings) {
	InputBox, TeamsWebhookURL, TweetMirror, Enter your MS Teams connector WebHook URL,,310,150,,,,,%TeamsWebhookURL%
	if (ErrorLevel) ; User cancelled
		GoTo, Aborted
	InputBox, TwitterScreenName, TweetMirror, Enter your Twitter username,,310,150,,,,,@
	if (ErrorLevel) ; User cancelled
		GoTo, Aborted
	InputBox, TweetHashtag, TweetMirror, Enter the hashtags you want to filter Tweets with,,310,150,,,,,#
	if (ErrorLevel) ; User cancelled
		GoTo, Aborted
	
	InputBox, ConsumerKey, TweetMirror, Enter your Twitter app's consumer key,,310,150
	if (ErrorLevel) ; User cancelled
		GoTo, Aborted
	InputBox, ConsumerSecret, TweetMirror, Enter your Twitter app's consumer secret,,310,150
	if (ErrorLevel) ; User cancelled
		GoTo, Aborted
	
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
	return
	
	Aborted:
		; If user has no settings saved, force them to reconfigure
		if (!hasFallbackSettings) {
			FirstTimeSetup(SettingsName, hasFallbackSettings)
		}
		return
}


; Takes a tweet object and sends it to MS teams
MirrorTweetToTeams(TeamsWebhookURL, tweetObj) {
	
	; Load teams card template JSON into object
	; Useful card builder: https://messagecardplayground.azurewebsites.net/
	FileRead, TeamsMsgTemplate, TeamsCardTemplate.json
	
	; Catch file load error
	if (ErrorLevel) {
		throw Exception("TeamsCardTemplate.json couldn't be read!", -1)
		return
	}
	TeamsMsgJSON := JSON.Load(TeamsMsgTemplate)
	
	; Process URLs in message
	copyText := tweetObj.full_text
	markdownText := tweetObj.full_text
	for index, urlObj in tweetObj.entities.urls {
		markdownText := StrReplace(markdownText, urlObj.url, "[" . urlObj.display_url . "]" . "(" . urlObj.expanded_url . ")")
		copyText := StrReplace(copyText, urlObj.url, urlObj.display_url)
	}
	
	; Fill URL preview area
	urlCount := tweetObj.entities.urls.length()
	if (urlCount = 0) {
		TeamsMsgJSON.sections[2] := []
	} else {
		targetURL := StrReplace(tweetObj.entities.urls[1].expanded_url, "\/", "/")
		
		; Extract metadata from URL
		metaHandler := New MetaFromURL(targetURL)
		pageTitle := metaHandler.GetPageTitle()
		pageDesription := metaHandler.GetPageDescription()
		metaHandler.Quit()
		
		; Fill default meta if required
		if (StrLen(pageTitle) < 3)
			pageTitle := tweetObj.entities.urls[1].display_url
		if (StrLen(pageDesription) < 3)
			pageDesription := "No description."
		

		; Populate template
		TeamsMsgJSON.sections[2].activityImage := "https://www.google.com/s2/favicons?domain_url=" . targetURL ; Use Google's favicon finder site to get icon
		TeamsMsgJSON.sections[2].activityTitle := pageTitle
		TeamsMsgJSON.sections[2].activityText := pageDesription
	}
	
	; Process hashtags in message
	hashtagRegex := "i)\B#([a-z0-9]{2,})(?![~!@#$%^&*()=+_`\-\|\/'\[\]\{\}]|[?.,]*\w)" ; Finds hashtags in text (excludes URLs, no spaces before etc)
	markdownText := RegExReplace(markdownText, hashtagRegex, "[#$1](https://twitter.com/hashtag/$1?src=hashtag_click)")

	; Fill in template:
	TeamsMsgJSON.title := tweetObj.user.name . " Tweeted:"
	TeamsMsgJSON.summary := tweetObj.user.name . " shared a Tweet."
	TeamsMsgJSON.potentialAction[1].targets[1].uri := "https://twitter.com/" . tweetObj.user.screen_name . "/status/" . tweetObj.id
	TeamsMsgJSON.sections[1].text := markdownText
	TeamsMsgJSON.potentialAction[2].targets[1].uri := "https://twitter.com/intent/tweet?text=" . UriEncode(copyText)
	
	; Turn JSON object to string
	TeamsMsgJSONStr := JSON.Dump( TeamsMsgJSON )

	; Send message to teams webhook
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", TeamsWebhookURL, true)
	whr.SetRequestHeader("Content-Type", "application/json")
	whr.Send(TeamsMsgJSONStr)
	whr.WaitForResponse()
}



GetTwitterAccessToken(SettingsName, ConsumerKey, ConsumerSecret) {
	BearerTokenCredentials := ConsumerKey . ":" . ConsumerSecret
	BearerTokenCredentialsEncoded := b64Encode(BearerTokenCredentials)
	AuthString := "Basic " . BearerTokenCredentialsEncoded
	
	; Post request to Twitter for auth token
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("POST", "https://api.twitter.com/oauth2/token", true)
	whr.SetRequestHeader("Authorization", AuthString)
	whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
	whr.Send("grant_type=client_credentials")
	
	; Wait for response to load
	whr.WaitForResponse()
	sleep 200

	; Parse JSON string into object
	authObj := JSON.Load(whr.ResponseText)
	
	; Cache token
	TwitterAccessToken := authObj.access_token
	IniWrite, %TwitterAccessToken%, %SettingsName%, Vars, TwitterAccessToken
	
	return %TwitterAccessToken%
}

; Returns rounded-down number of seconds until next check for new tweets
GetSecondsUntilNextCheck(NextPoll) {
	return Floor((NextPoll - A_TickCount) / 1000)
}

; Checks for new Tweets and appropriate ones to MS Teams
; Returns true if check was successful (no errors)
ProcessTwitterUpdates(NextPoll, TwitterAccessToken, LastTweetID, TweetHashtag, TeamsWebhookURL, SettingsName) {
	; Get tweets
	TweetsURL := GetTweetsAPIURL("lloydjason94", LastTweetID)
	MyTweetsJSON := ProcessTwitterAPICall(TwitterAccessToken, TweetsURL)
	if (!MyTweetsJSON)
		return false
	MyTweets := JSON.Load(MyTweetsJSON) ; Convert JSON to object
	
	; Check if Twitter blocked the call
	if (MyTweets.errors) {
		errorMsg := MyTweets.errors[1].message
		Menu, Tray, Tip, TweetMirror error: %errorMsg%
		return false
	}
	
	; Stop if no new tweets found
	newTweetCount := MyTweets.Length()
	if (newTweetCount = 0) {
		SetTimer UpdateMenuTip, 1000 ; Endlessly runs tray tooltip updater
		return true
	}
	
	; Process new tweets
	counter := newTweetCount
	mirroredTweets := 0
	Loop %newTweetCount% {
		tweet := MyTweets[counter]
		
		; If tweet contains desired hashtag, forward to MS Teams
		hashtagRegex := "i)\B#" . TweetHashtag . "(?![~!@#$%^&*()=+_`\-\|\/'\[\]\{\}]|[?.,]*\w)" ; Finds hashtags in text (excludes URLs, no spaces before etc)
		foundPos := RegexMatch(tweet.full_text, hashtagRegex, hashtagFound)
		
		if (foundPos) {
			MirrorTweetToTeams(TeamsWebhookURL, tweet)
			mirroredTweets++
		}
		
		counter--
	}
	
	; Update tray tooltip text
	if (mirroredTweets) {
		plural := ""
		if (mirroredTweets > 1)
			plural := "s"
		Menu, Tray, Tip, %mirroredTweets% new #%TweetHashtag% Tweet%plural% recently mirrored!
	} else {
		SetTimer UpdateMenuTip, 1000 ; Endlessly runs tray tooltip updater
		return true
	}
	MsgBox, Mirrored
	
	; Update last processed tweet ID
	; This speeds up future calls to Twitter API and tweet processing
	LastTweetID := MyTweets[1].id
	IniWrite, %LastTweetID%, %SettingsName%, Vars, LastTweetID
	
	return true
}



; If setting file doesn't exist run first time setup
if (!FileExist(SettingsName)) {
	MsgBox, Thanks for downloading my tool! To use it, you must setup your details...
	FirstTimeSetup(SettingsName, false)
}

; Load settings into global variables
IniRead, TeamsWebhookURL, %SettingsName%, Settings, TeamsWebhookURL
IniRead, TwitterScreenName, %SettingsName%, Settings, TwitterScreenName
IniRead, TweetHashtag, %SettingsName%, Settings, TweetHashtag

IniRead, ConsumerKey, %SettingsName%, Settings, ConsumerKey
IniRead, ConsumerSecret, %SettingsName%, Settings, ConsumerSecret

IniRead, LastTweetID, %SettingsName%, Vars, LastTweetID
IniRead, TwitterAccessToken, %SettingsName%, Vars, TwitterAccessToken




; Get Twitter app (FreddieDevTweetMirror) access token if none is cached
if (TwitterAccessToken = error or StrLen(TwitterAccessToken) = 0) {
	TwitterAccessToken := GetTwitterAccessToken(SettingsName, ConsumerKey, ConsumerSecret)
}

; Endlessly run checks for new tweets
Loop {
	Menu, Tray, Icon, shell32.dll, %LOADING_ICON%
	
	; Add time to next poll time
	NextPoll += PollRate
	
	; Check for new tweets
	IniRead, LastTweetID, %SettingsName%, Vars, LastTweetID
	ProcessSuccessful := ProcessTwitterUpdates(NextPoll, TwitterAccessToken, LastTweetID, TweetHashtag, TeamsWebhookURL, SettingsName)
	
	if (!ProcessSuccessful) {
		Menu, Tray, Icon, shell32.dll, %ERROR_ICON%
		Menu, Tray, Tip, Error occurred when polling Twitter... regenerating auth key.
		TwitterAccessToken := GetTwitterAccessToken(SettingsName, ConsumerKey, ConsumerSecret)
	} else {
		Menu, Tray, Icon, %DEFAULT_ICON% ; Restore default icon
	}
	
	Sleep, PollRate
}

return ; Stop handlers running on script start




MenuHandler:
	if (A_ThisMenuItem = MenuReloadScriptText) {
		Reload
		return
	} else if (A_ThisMenuItem = MenuExitScriptText) {
		ExitApp
	} else if (A_ThisMenuItem = MenuChangeSettingsText) {
		FirstTimeSetup(SettingsName, true)
	}

	return

; Loops in background updating tray menu tooltip until a check is about to start
UpdateMenuTip:
	secondsTilCheck := GetSecondsUntilNextCheck(NextPoll)
	
	if (secondsTilCheck <= 1) {
		SetTimer UpdateMenuTip, Delete
	}
	
	Menu, Tray, Tip, No new #%TweetHashtag% Tweets (next check: %secondsTilCheck% seconds)
	return
