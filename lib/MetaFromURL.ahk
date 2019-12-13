; Lib to get page meta details (title and description) from their URL

class MetaFromURL {
	Static CurrentSession :=
	currentURL :=

	__New(pageURL) {
		This.currentURL := pageURL
		
		; Use get request to pull HTML from site as string
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", pageURL, true) ; True waits for response before continuing
		whr.Send()
		whr.WaitForResponse()
		HtmlText := whr.ResponseText

		; Use HTML renderer so JS can be ran on HTML string
		This.CurrentSession := ComObjCreate("HTMLFile")
		This.CurrentSession.write(HtmlText)
	}
	
	Quit() {
		This.CurrentSession.Close()
	}

	GetPageTitle() {
		return This.CurrentSession.getElementsByTagName("title")[0].text
	}
	GetPageDescription() {
		return "I dont know"
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