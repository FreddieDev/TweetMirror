# TweetMirror
Detects new tweets that contain a desired hashtag to forward them onto MS Teams automatically


## How to use
### Configuring Teams and Twitter
1. Obtain a Twitter app consumer key and secret:
	- Go to https://developer.twitter.com/en/apps and create an app
	- Message me to use mine
2. In MS Teams, right click the channel you want to mirror your Tweets to
3. Select "Connectors"
4. Add or Configure "Incoming Webhook" (under all)
5. Name the WebHook TweetMirror (you may also [upload the icon](../../master/artwork/TweetMirror%20-%20Small.png))
6. Select Create
7. Copy the generated WebHook URL

### Installing the script
1. Click [here](../../archive/master.zip) to download the app
2. Unzip the file
3. Run `install.bat`
4. Fill in all the prompted fields
	- If you've made mistakes, right click the tray icon and select "Change Settings" to reconfigure
4. You can now delete the downloaded files to cleanup


## Removing the script
Download and run `uninstall.bat`

## Disabing startup launch
By default, TweetMirror launches on startup. This can be disabled via the startup tab in Task Manager.