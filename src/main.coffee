playlist = null

STATE_UNSTARTED = -1
STATE_ENDED = 0
STATE_PLAYING = 1
STATE_PAUSED = 2
STATE_BUFFERING = 3
STATE_VIDEO_CUED = 5

playlist = new Playlist()

chrome.tabs.onRemoved.addListener (tabId) ->
	playlist.removeVideo tabId, () ->
		playlist.getList()

chrome.extension.onMessage.addListener (request, sender) ->
	return unless request?
	switch request.event
		when 'Greetings'
			@playlist.addVideo sender.tab.id, sender.tab.title,  () ->
				@playlist.stopVideo sender.tab.id
		when 'stateChange'
			onStateChange request.state, sender.tab.id
		else console.error "unknown event: #{request.event}"

onStateChange = (state, tabId) ->
	switch state
		when STATE_UNSTARTED
			console.log "STATE_UNSTARTED"
		when STATE_PLAYING
			console.log "STATE_PLAYING"
			playlist.setPlaying tabId
		when STATE_PAUSED
			console.log "STATE_PAUSED"
			playlist.setPaused()
		when STATE_BUFFERING
			console.log "STATE_BUFFERING"
		when STATE_ENDED
			console.log "STATE_ENDED"
			playlist.playNext()
		when STATE_VIDEO_CUED
			console.log "STATE_VIDEO_CUED"

sendMsg = (tabId, msg) ->
	chrome.tabs.sendMessage tabId, msg