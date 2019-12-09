; Lib to get page meta details (title and description) from their URL


class MetaFromURL {
	Static CurrentSession :=

	__New(pageURL) {
		This.CurrentSession := ComObjCreate("InternetExplorer.Application") ; Creates an Internet Explore COM object
		This.CurrentSession.visible := false ; Hide IE window
		This.CurrentSession.navigate(pageURL)

		; Ensure webpage completely loads before continuing
		while This.CurrentSession.ReadyState != 4
			Sleep, 100
	}

	; Ends IE process for current session
	Quit() {
		This.CurrentSession.quit
	}


	GetPageTitle() {
		return This.CurrentSession.document.querySelector("[property='og:title']").content
	}
	GetPageDescription() {
		return This.CurrentSession.document.querySelector("[property='og:description']").content
	}
}