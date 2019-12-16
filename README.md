# TweetMirror
Detects new tweets that contain a desired hashtag to forward them onto MS Teams automatically


## How to use
### Installing
1. Click [here](../../archive/master.zip) to download the app
2. Unzip the file
3. Run `install.bat`
4. Fill in all the prompted fields
	- If you've made mistakes, right click the tray icon and select "Change Settings" to reconfigure
4. You can now delete the downloaded files to cleanup

### Obtaining an MS Teams Webhook URL
1. In Teams, right click the channel you want to mirror your Tweets to
2. Click "Connectors"
3. Press "Add" or "Configure" on the "Incoming Webhook" connector
4. Enter any name (you may also [upload the icon](../../master/artwork/TweetMirror%20-%20Teams.png?raw=true))
5. Press "Create"
6. Copy the generated WebHook URL

### Obtain Twitter consumer keys
To bbtain a Twitter app consumer key and secret:
- Go to https://developer.twitter.com/en/apps and create an app
- Message me to use mine


### Disabing startup launch
By default, TweetMirror launches on startup. This can be disabled via the startup tab in Task Manager.

### Uninstalling
Download and run `uninstall.bat`


## Developing
To recompile the exe:
1. Install [AutoHotkey](https://www.autohotkey.com/)
2. Reboot (if step 3 fails)
3. Right click the `.ahk` and select "Compile Script"
