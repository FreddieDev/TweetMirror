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
	
	GetMetaContent(propertyName) {
		metaTags := This.CurrentSession.getElementsByTagName("meta")
		
		; AHK for-loop doesn't work due to how HTMLFile returns a weird object
		while (A_Index<=metaTags.length, i:=A_Index-1) {
			metaTag := metaTags[i]
			if (metaTag.getAttribute("name") == propertyName) {
				return metaTag.getAttribute("content")
			}
		}
		
		return false
	}

	GetPageTitle() {
		local titleText
		
		try {
			titleText := This.CurrentSession.getElementsByTagName("title")[0].text
		}
		
		if (!titleText) {
			titleText := This.GetMetaContent("title")
		}
		
		return titleText
	}
	
	GetPageDescription() {
		description := This.GetMetaContent("description")
		
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
	
	GetIconURL() {	
		iconURL := This.GetLinkHref("apple-touch-icon") ; Apple icons are the best quality

		if (!iconURL)
			iconURL := This.GetLinkHref("favicon", ".ico") ; Find non-.ico icons (unsupported by MS teams)

		if (!iconURL)
			iconURL := "https://www.google.com/s2/favicons?domain_url=" . This.CurrentURL ; Use Google's favicon finder site to get low-res icon (png) as fallback
	
		MsgBox, %iconURL%
		return iconURL
	}
}