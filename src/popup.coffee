document.addEventListener 'DOMContentLoaded', () ->
	bkg = chrome.extension.getBackgroundPage()
	playlist = bkg.playlist

	DOMPlaylist = document.getElementById 'playlist'

	createPlaylistItem = (tabId, videoObject) ->
		a  = document.createElement 'a'
		a['data-tabId'] = tabId
		a['href']       = '#'
		a['innerHTML']  = videoObject.title
		
		a.addEventListener 'click', (e) ->
			tabId = a['data-tabId']
			playlist.playVideo tabId
			chrome.tabs.update tabId, selected: true
		
		li = document.createElement 'li'
		li.appendChild a
		return li

	renderPlaylist = () ->
		DOMPlaylist.innerHTML = ""
		for id in playlist.getPriority()
			video = playlist.getList()[id]
			li = createPlaylistItem id, video
			DOMPlaylist.appendChild li

	playlist.subscribeEvent 'add:video', (tabId, videoObject) ->
		renderPlaylist()

	playlist.subscribeEvent 'remove:video', (tabId) ->
		renderPlaylist()

	renderPlaylist()
