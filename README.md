# TweetMirror
Detects new tweets that contain a desired hashtag to forward them onto MS Teams automatically.

TweetMirror runs checks periodically in the background of your PC. You can force a check by double-clicking the tray icon.


## How to use
### Installing
1. Click [here](../../archive/master.zip) to download the app
2. Unzip the file and run `installer.bat`
3. Fill in all the prompted fields
	- If you've made mistakes, right click the tray icon and select "Change Settings" to reconfigure
	- You can now delete the downloaded files to cleanup

### Obtaining an MS Teams Webhook URL
1. In Teams, right click the channel you want to mirror Tweets to
2. Click "Connectors"
3. Press "Add" or "Configure" on the "Incoming Webhook" connector
4. Enter a name (you may also [upload the icon](../../master/TweetMirror%20Teams%20icon.png?raw=true))
5. Press "Create" and copy the generated WebHook URL

### Obtain Twitter consumer keys
To get a Twitter app consumer key and secret, either:
- Contact me for mine
- Go to https://developer.twitter.com/en/apps and create an app for your own

### Uninstalling/repairing
1. Click [here](../../archive/master.zip) to download the app
2. Unzip the file and run `installer.bat`


<br/>
<br/>

## Developing
1. Install [AutoHotkey](https://www.autohotkey.com/)
2. Reboot (if step 3 fails)
3. Run `Compile TweetMirror.bat` to recompile all AHK scripts after making changes
