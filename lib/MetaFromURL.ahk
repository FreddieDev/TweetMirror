; Lib to get page meta details (title and description) from their URL

class MetaFromURL {
	CurrentSession :=
	CurrentURL :=

	__New(pageURL) {
		This.CurrentURL := pageURL
		
		; Use get request to pull HTML from site as string
		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", pageURL, true) ; True waits for response before continuing
		whr.Send()
		whr.WaitForResponse()
		HTMLText := whr.ResponseText
		
		; Remove all scripts and CSS from HTML for faster rendering
		; Removing scripts is necessary since any cookies set produce an old windows security warning request for the site to store cookies
		strippedHTML := RegExReplace(HTMLText, "i)<(script|style)\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/(script|style)>", "")

		; Use HTML renderer so JS can be ran on HTML string
		This.CurrentSession := ComObjCreate("HTMLFile")
		This.CurrentSession.write(strippedHTML)
	}
	
	Quit() {
		This.CurrentSession.Close()
	}
	
	GetMetaContent(attributeName, propertyName) {
		metaTags := This.CurrentSession.getElementsByTagName("meta")
		
		; AHK for-loop doesn't work due to how HTMLFile returns a weird object
		while (A_Index<=metaTags.length, i:=A_Index-1) {
			metaTag := metaTags[i]
			
			if (metaTag.getAttribute(attributeName) == propertyName) {
				return metaTag.getAttribute("content")
			}
		}
		
		MsgBox, %tagnames%
		
		return false
	}

	GetPageTitle() {
		titleText := This.GetMetaContent("property", "og:title") ; Try to get meta title
		
		; Fallback to Twitter card's title
		if (!titleText)
			titleText := This.GetMetaContent("name", "twitter:title")
		
		; Final fallback, fetch page's title element text instead if one exists
		try {
			titleText := This.CurrentSession.getElementsByTagName("title")[0].text
		}
		
		return titleText
	}
	
	GetPageDescription() {
		description := This.GetMetaContent("property", "og:description") ; Try to get page description
		
		; Fallback to Twitter card description
		if (!description)
			description := This.GetMetaContent("name", "twitter:description")		
		
		; If none found, just output no description
		if (!description)
			description := "No description"
		
		return description
	}
	
	; Finds the last matching (likely most-HD) link's href
	;  searchText is text the link MUST include
	;  filterText (optional) is text the link must NOT include
	GetLinkHref(searchText, filterText:=false) {
		links := This.CurrentSession.getElementsByTagName("link")
		
		; AHK for-loop doesn't work due to how HTMLFile returns a weird object
		while (A_Index<=links.length, i:=links.length-A_Index) {
			linkElem := links[i]

			if (InStr(linkElem.href, searchText) and (!filterText or !InStr(linkElem.href, filterText)) ) {
				currURL := This.CurrentURL
				SplitPath, currURL, name, dir, ext, name_no_ext, drive ; Split URL into parts
				
				; Some sites use relative URLs for files, while some use the full address. For instance: 
				;  /media/favicon.ico
				;  https://www.google.com/media/favicon.ico
				;
				; We ALWAYS need the full address. To solve this, this regex removes the protocol & domain (if it exists) so it can later be re-added				
				targetURL := RegExReplace(linkElem.href, "i)^(?:\/\/|[^\/]+)*", "")
			
				return drive . targetURL ; Add domain name onto URL
			}
		}
		
		return false
	}
	
	; Function to fetch icon from page
	; These can be tested in the Chrome debugger like so:
	;  document.querySelector("meta[property='og:image']").getAttribute('content')
	;  document.querySelector("link[href*=apple-touch-icon]").href
	;  document.querySelectorAll("link[href*=favicon]:not([href*='.ico']")
	GetIconURL() {
		iconURL := This.GetLinkHref("apple-touch-icon") ; Apple icons are the best quality
		
		; Get any icon (excluding .ico's, since teams can't render them)
		if (!iconURL)
			iconURL := This.GetLinkHref("favicon", ".ico") ; Find non-.ico icons (unsupported by MS teams)
		
		; Try article img (likely not correct aspect ratio)
		if (!iconURL)
			iconURL := This.GetMetaContent("property", "og:image")
			
		; Try Twitter card image (likely not correct aspect ratio)
		if (!iconURL)
			iconURL := This.GetMetaContent("name", "twitter:image")
		
		; Use Google's favicon finder site to get low-res icon (png) as fallback
		if (!iconURL)
			iconURL := "https://www.google.com/s2/favicons?domain_url=" . This.CurrentURL
	
		return iconURL
	}
}