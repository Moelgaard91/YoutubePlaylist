STATE_UNSTARTED  = -1
STATE_ENDED      = 0
STATE_PLAYING    = 1
STATE_PAUSED     = 2
STATE_BUFFERING  = 3
STATE_VIDEO_CUED = 5

# constructs a playlist
playlist = new Playlist

# listener that removes a video from the playlist, if it's tab is closed.
chrome.tabs.onRemoved.addListener (tabId) ->
	playlist.removeVideo tabId, () ->
		playlist.getList()

# initialize event listeners of the message channels
# between the content scripts, that is injected into the DOM.
# greeting is send from the content script,
# to let us know that the dom has been initialize,
# and we adds the video to the playlist, and sets its state to pasued,
# futhermore we listens to state changes of the video.
chrome.extension.onMessage.addListener (request, sender) ->
	return unless request?
	switch request.event
		when 'Greetings'
			@playlist.addVideo sender.tab.id, sender.tab.title,  () ->
				@playlist.stopVideo sender.tab.id
		when 'stateChange'
			onStateChange request.state, sender.tab.id
		else console.error "unknown event: #{request.event}"

###
# The state chenge handler.
# @param string state
# @param integer tabId
# @return void
###
onStateChange = (state, tabId) ->
	switch state
		when STATE_PLAYING
			playlist.setPlaying tabId
		when STATE_PAUSED
			playlist.setPaused tabId
		when STATE_ENDED
			playlist.playNext()
		# when STATE_UNSTARTED
		# when STATE_BUFFERING
		# when STATE_VIDEO_CUED 

###
# Send a message to the content script of a given tab.
# @param integer tabId
# @param mixed msg
# @return void
###
sendMsg = (tabId, msg) ->
	chrome.tabs.sendMessage tabId, msg