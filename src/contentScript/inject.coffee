# Get the reference to the video player.
player = document.getElementById 'movie_player'

###
# Initialize the listeners, that polls the player state.
# in order to letting the rest of the extension know,
# when the state changes.
# @return void
###
initListeners = () ->
	# the current state
	state = null
	# previous state
	prevState = null

	# sending a greeting message to the extension,
	# letting it know, that the DOM is loaded of this video page.
	chrome.extension.sendMessage event: 'Greetings'

	# hooking up listeners, so the extension can start and stop a video.
	chrome.extension.onMessage.addListener (request, sender) ->
		return unless request?
		switch request
			when 'stop' then do player.stopVideo
			when 'play' then do player.playVideo
			else console.error "unknown action: #{request.action}"

	# start the player state polling.
	setInterval () ->
		state = player.getPlayerState()
		return if state is prevState
		prevState = state
		chrome.extension.sendMessage
			event: 'stateChange'
			state: state
	, 200

# the reset counter, of finding out when the video is loaded.
# if the video isnt loaded in 10 seconds, after the DOM is loaded,
# then we cannot communicate with it.
# When the player is loaded, hook up events.
counter = 0
isYoutubePlayerLoaded = () ->
	return console.error "YoutubePlayer is never loaded after 30 tries" if counter >= 100
	if player.getPlayerState?
		return initListeners()
	else
		counter++
		return setTimeout () ->
			isYoutubePlayerLoaded()
		, 100

# start the "player is loaded" polling.
isYoutubePlayerLoaded()
