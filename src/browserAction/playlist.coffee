# waits to the DOM is loaded.
document.addEventListener 'DOMContentLoaded', () ->
	
	# retrieve the background script of the extension.
	bkg = chrome.extension.getBackgroundPage()

	# the playlist object
	playlist = bkg.playlist

	# find the the playlist ul DOM element.
	DOMPlaylist = document.getElementById 'playlist'

	###
	# Toggling a control button's state.
	# @param integer tabId
	# @param boolean state
	# @return void
	###
	toggleControlButtonState = (tabId, state) ->
		return unless (icon = document.getElementById "control-icon-#{tabId}")?
		if state then icon['className'] = 'icon-pause' else icon['className'] = 'icon-play'

	###
	# Create a control button.
	# @param Video video
	# @return HTMLButtonElement
	###
	createControls = (video) ->
		btn = document.createElement 'button'
		btn['className'] = 'btn btn-mini pull-right'
		btn['id'] = "control-btn-#{video.tabId}"
		btn['data-tabId'] = video.tabId
		
		i = document.createElement 'icon'
		i['id'] = "control-icon-#{video.tabId}"
		i['data-tabId'] = video.tabId
		if video.playing then	i['className'] = 'icon-pause' else i['className'] = 'icon-play'
		
		# listens to when the a video is playing.
		# to change the icon of the control button.
		video.subscribeEvent 'change:playing', (state) ->
			toggleControlButtonState @tabId, state
		
		# listens to when the control button is clicked,
		# to either start or stop the video.
		btn.addEventListener 'click', (e) ->
			e.stopPropagation()
			tabId = btn['data-tabId']
			i = document.getElementById "control-icon-#{tabId}"
			if i['className'] is "icon-play"
				playlist.playVideo tabId
				isPlaying = yes
			else
				playlist.stopVideo tabId
				isPlaying = no

			toggleControlButtonState tabId, isPlaying
			return false

		btn.appendChild i
		return btn

	###
	# Create a playlist item.
	# @param integer tabId
	# @param Video video
	# @return HTMLLiElement
	###
	createPlaylistItem = (tabId, video) ->
		a  = document.createElement 'a'
		a['data-tabId'] = tabId
		a['href']       = '#'
		a['innerHTML']  = video.title
		
		if tabId isnt -1
			a.appendChild createControls video
			a.addEventListener 'click', (e) ->
				tabId = a['data-tabId']
				chrome.tabs.update tabId, selected: true
		else
			a['className'] = "empty"
		
		li = document.createElement 'li'
		li.appendChild a
		return li

	###
	# Render the playlist.
	# @return void
	###
	renderPlaylist = () ->
		DOMPlaylist.innerHTML = ""
		if playlist.getPriority().length is 0
			DOMPlaylist.appendChild createPlaylistItem -1, title: "The playlist is empty."
		else
			for id in playlist.getPriority()
				video = playlist.getList()[id]
				DOMPlaylist.appendChild createPlaylistItem id, video

	# listens to when the a video is added to the playlist.
	playlist.subscribeEvent 'add:video', (tabId, videoObject) ->
		renderPlaylist()

	# listens to when a video is removed to the playlist.
	playlist.subscribeEvent 'remove:video', (tabId) ->
		renderPlaylist()

	# render the playlist when the DOM is loaded.
	renderPlaylist()
