; Lib to get page meta details (title and description) from their URL

class MetaFromURL {
	Static CurrentSession :=
	currentURL :=

	__New(pageURL) {
		This.currentURL := pageURL
		
		; This.CurrentSession := ComObjCreate("{D5E8041D-920F-45e9-B8FB-B1DEB82C6E5E}") ; Creates an InternetExplorerMedium instance (lowered security)
		This.CurrentSession := ComObjCreate("InternetExplorer.Application") ; Creates an InternetExplorerMedium instance (lowered security)
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
	GetIconURL() {	
		local iconURL
		try {
			iconURL := This.CurrentSession.document.querySelector("link[href*=apple-touch-icon]").href
		}
		
		if (!iconURL)
			try {
				iconURLs := This.CurrentSession.document.querySelectorAll("link[href*=favicon]:not([href*='.ico']") ; Returns a JS object array (unknown format for AHK, .length won't work)
				iconURLsLen := This.CurrentSession.document.querySelectorAll("link[href*=favicon]:not([href*='.ico']").length
				
				iconURL := iconURLs[iconURLsLen - 1].href ; Get last (most likely most-HD) icon on page
			}
		
		if (!iconURL)
			iconURL := "https://www.google.com/s2/favicons?domain_url=" . This.currentURL ; Use Google's favicon finder site to get low-res icon as fallback
		MsgBox, %iconURL%
		return iconURL
	}
}