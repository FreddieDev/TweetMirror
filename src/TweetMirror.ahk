#Persistent  ; Keep the script running until the user exits it.
#SingleInstance force ; Only allow one instance of this script and don't prompt on replace
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SettingsName := "TweetMirror.ini"

#Include lib\lib.ahk
#Include lib\JSON.ahk
#Include lib\MetaFromURL.ahk
#Include lib\Settings.ahk

; Developer settings
global debugMode := false ; Set to true to pause after mirroring tweets without updating LastTweetID (no need to tweet every test, simply un-pause)

; Global vars (leave empty, `global` shares them with included scripts)
global TeamsWebhookURL :=
global TwitterScreenName :=
global TweetHashtag :=
global ConsumerKey :=
global ConsumerSecret :=
global LastTweetID :=
global TwitterAccessToken :=

; Global vars (hard-coded settings)
PollRate := 30000 ; How frequently to check for new tweets
MaxSearchedTweets := 20 ; The maximum amount of Tweets to look through
ERROR_ICON := 78
LOADING_ICON := 239
DEFAULT_ICON := StrReplace(A_ScriptFullPath, ".ahk", ".exe")
NextPoll := A_TickCount
global MaxRedirects := 10 ; How many times to attempt to unshorten a URL max before giving up
global MaxCharsInDisplayURL := 30 ; How many characters to display in a URL in teams before trimming and adding an ellipses (URL still clickable)




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
MenuReloadScriptText := "Restart"
Menu, Tray, Add, %MenuReloadScriptText%, MenuHandler

; Add option to exit the current script
MenuExitScriptText := "Exit"
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


; Sends HTTP request to URL to see if it returns a redirect URL
UnShortenURL(urlToShorten) {

	; Get headers from URL's server
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("HEAD", urlToShorten, true) ; True waits for response before continuing
	whr.Send()
	whr.WaitForResponse()
	
	; If status 3XX (e.g. 301, 304 etc) is returned, the server is returning
	; a msg containing a redirect 'Location' header
	newURL :=
	if (Floor(whr.status / 100) == 3) {
		newURL := whr.getResponseHeader("Location")
	} else {
		; Sometimes URL shortening is automatic, so just return the final
		; URL (will either be shortened or the same)
		newURL := whr.Option(1) ; WinHttpRequestOption_URL == 1
	}
	
	return newURL
}

; Takes a full URL and strips domain, protocol and crops the length
GenerateDisplayURL(urlToClean) {
	
	; Remove protocol (https/http) and www.
	cleanedURL := RegExReplace(urlToClean, "i)^(?:https?:\/\/)?(?:www\.)?", "")
	
	; If URL is too long, remove chars from end and add "..."
	if (strLen(cleanedURL) > 30) {
		cleanedURL := SubStr(cleanedURL, 1, MaxCharsInDisplayURL - 3) . "..."
	}
	
	return cleanedURL
}


; Takes a tweet object and sends it to MS teams
MirrorTweetToTeams(TeamsWebhookURL, tweetObj) {
	
	; Load teams card template JSON into object
	; Useful card builder: https://messagecardplayground.azurewebsites.net/
	;  Examples used: TINYPulse & Trello update
	; UPDATE: Microsoft has discontinued support for legacy message cards in the playground,
	;         despite this being the only card format supported by Connectors/Webhooks
	FileRead, TeamsMsgTemplate, lib\TeamsCardTemplate.json
	
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
		
		; Process URL shorteners (bit.ly, tinyURL, Twitter/t.co, LinkedIn/lnkd.in etc)
		fullURL := UnShortenURL(urlObj.expanded_url)
		
		; Keep attempting unshortening until the URL remains the same
		; This allows shortened shortened (etc) URLs to be expanded
		;
		; People regularly do this when copying LinkedIn URLs from Twitter e.g:
		;  t.co > lnkd.in > URL
		Loop, %MaxRedirects% {
			newFullURL := UnShortenURL(fullURL)
			if (newFullURL = fullURL)
				break
			else
				fullURL := newFullURL
		}
		
		if (debugMode)
			MsgBox, Unshortened URL: %fullURL%
		
		; Update Twitter object's URL
		urlObj.expanded_url := fullURL
		
		; Build a new clean display URL so it's unshortened and readable
		urlObj.display_url := GenerateDisplayURL(fullURL)
	
		markdownText := StrReplace(markdownText, urlObj.url, "[" . urlObj.display_url . "]" . "(" . fullURL . ")")
		copyText := StrReplace(copyText, urlObj.url, fullURL)
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
		pageIcon := metaHandler.GetIconURL()
		metaHandler.Quit()
		
		; If no title is supplied, replace with display URL
		if (StrLen(pageTitle) < 3)
			pageTitle := tweetObj.entities.urls[1].display_url
		

		; Populate template
		TeamsMsgJSON.sections[2].activityImage := pageIcon
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
	
	teamsReply := whr.ResponseText
	if (teamsReply != "1")
		MsgBox, "Error posting in Teams: " . teamsReply
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
	
	; Tell user if an error has occured
	if (authObj.errors) {
		errorMsg := authObj.errors[1].message
		MsgBox, Error authenticating with Twitter: %errorMsg%
	}
	
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
ProcessTwitterUpdates() {
	global
	
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
	
	if (debugMode) {
		MsgBox, Mirrored
		return true
	}
	
	; Update last processed tweet ID
	; This speeds up future calls to Twitter API and tweet processing
	LastTweetID := MyTweets[1].id
	IniWrite, %LastTweetID%, %SettingsName%, Vars, LastTweetID
	
	return true
}


ShowError(msg) {
	Menu, Tray, Icon, shell32.dll, %ERROR_ICON%
	Menu, Tray, Tip, %msg%
}

StartTweetMirror() {
	global
	
	; Get Twitter app (FreddieDevTweetMirror) access token if none is cached
	if (StrLen(TwitterAccessToken) == 0 or TwitterAccessToken = error) {
		try {
			TwitterAccessToken := GetTwitterAccessToken(SettingsName, ConsumerKey, ConsumerSecret)
		} catch e {
			ShowError("Error generating Twitter auth key: %e%")
		}
	}

	; Endlessly run checks for new tweets
	Loop {
		Menu, Tray, Tip, Checking for new Tweets...
		Menu, Tray, Icon, shell32.dll, %LOADING_ICON%
		
		; Add time to next poll time
		NextPoll := A_TickCount + PollRate
		
		; Check for new tweets
		IniRead, LastTweetID, %SettingsName%, Vars, LastTweetID
		ProcessSuccessful := ProcessTwitterUpdates()
		
		if (!ProcessSuccessful) {
			ShowError("Error occurred when polling Twitter... regenerating auth key.")
			try {
				TwitterAccessToken := GetTwitterAccessToken(SettingsName, ConsumerKey, ConsumerSecret)
			} catch e {
				Menu, Tray, Tip, Error generating Twitter auth key: %e%
				ShowError("Error generating Twitter auth key: %e%")
			}
		} else {
			Menu, Tray, Icon, %DEFAULT_ICON% ; Restore default icon
		}
		
		Sleep, PollRate
	}
}


; If setting file doesn't exist run first time setup
if (!FileExist(SettingsName)) {
	MsgBox, Thanks for downloading my tool! To use it, you must setup your details...
	Settings.Change()
} else {
	Settings.Load()
	StartTweetMirror()
}


return ; Stop handlers running on script start


GuiClose:
	Gui, Destroy
	return

ButtonSave:
	Gui, Submit ; Save the input from the user to each control's associated variable.
	Settings.Save()
	Gui, Destroy
	return




MenuHandler:
	if (A_ThisMenuItem = MenuReloadScriptText) {
		Reload
		return
	} else if (A_ThisMenuItem = MenuExitScriptText) {
		ExitApp
	} else if (A_ThisMenuItem = MenuChangeSettingsText) {
		; FirstTimeSetup(SettingsName, true)
		Settings.Change()
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
