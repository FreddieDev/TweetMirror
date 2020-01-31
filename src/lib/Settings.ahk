class Settings {
	Change() {
		global
		Gui, Destroy ; Close existing windows
		
		Gui, Add, Text,, Twitter handle to mirror:
		Gui, Add, Edit, vTwitterScreenName w135, @%TwitterScreenName%

		Gui, Add, Text,, Hashtag to filter:
		Gui, Add, Edit, vTweetHashtag w100, #%TweetHashtag%

		; Add a fairly wide edit control at the top of the window.
		Gui, Add, Text,, MS Teams Webhook URL:
		gui, add, Edit, vTeamsWebhookURL w330 h60, %TeamsWebhookURL%


		; Bold header
		Gui, Font, W700,
		Gui, Add, Text, x10 y200, Twitter app info:
		Gui, Font, W400,

		gui, add, text, section, Consumer key:  ; Save this control's position and start a new section.
		gui, add, text,, Consumer secret:
		gui, add, Edit, vConsumerKey ys w235, %ConsumerKey% ; Start a new column within this section.
		gui, add, Edit, vConsumerSecret w235 h50, %ConsumerSecret%

		; Save button
		gui, add, text, section
		Gui, Add, Button, xm Center x140 h27 w70, Save

		gui, show,, TweetMirror Settings
	}

	Save() {
		global
		
		; Strip unneeded characters
		TwitterScreenName := Trim(StrReplace(TwitterScreenName, "@"))
		TweetHashtag := Trim(StrReplace(TweetHashtag, "#"))
		ConsumerKey := Trim(ConsumerKey)
		ConsumerSecret := Trim(ConsumerSecret)
		
		; Write user's settings
		IniWrite, %TeamsWebhookURL%, %SettingsName%, Settings, TeamsWebhookURL
		IniWrite, %TwitterScreenName%, %SettingsName%, Settings, TwitterScreenName
		IniWrite, %TweetHashtag%, %SettingsName%, Settings, TweetHashtag
		
		IniWrite, %ConsumerKey%, %SettingsName%, Settings, ConsumerKey
		IniWrite, %ConsumerSecret%, %SettingsName%, Settings, ConsumerSecret
		
		StartTweetMirror()
	}

	Load() {
		global
		
		; Load settings into global variables
		IniRead, TeamsWebhookURL, %SettingsName%, Settings, TeamsWebhookURL
		IniRead, TwitterScreenName, %SettingsName%, Settings, TwitterScreenName
		IniRead, TweetHashtag, %SettingsName%, Settings, TweetHashtag

		IniRead, ConsumerKey, %SettingsName%, Settings, ConsumerKey
		IniRead, ConsumerSecret, %SettingsName%, Settings, ConsumerSecret

		IniRead, LastTweetID, %SettingsName%, Vars, LastTweetID
		IniRead, TwitterAccessToken, %SettingsName%, Vars, TwitterAccessToken
	}
}