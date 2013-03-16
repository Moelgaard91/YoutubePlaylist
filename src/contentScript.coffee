console.log "contentScript loaded"
console.log "document state: " + document.readyState

player = document.getElementById('movie_player')
console.log "player loaded"

initListeners = () ->
	state = null
	prevState = null

	chrome.extension.sendMessage event: 'Greetings'

	chrome.extension.onMessage.addListener (request, sender) ->
		console.log 'Message received: ' + request
		console.log 'sender.tab.url: ' + sender.tab.url
		return unless request?
		switch request
			when 'stop' then do player.stopVideo
			when 'play' then do player.playVideo
			else console.error "unknown action: #{request.action}"

	setInterval () ->
		state = player.getPlayerState()
		return if state is prevState
		prevState = state
		chrome.extension.sendMessage
			event: 'stateChange'
			state: state
	, 200

counter = 0
isYoutubePlayerLoaded = () ->
	return console.error "YoutubePlayer is never loaded after 30 tries" if counter >= 30
	if player.getPlayerState?
		return initListeners()
	else
		counter++
		return setTimeout () ->
			isYoutubePlayerLoaded()
		, 100

isYoutubePlayerLoaded()
