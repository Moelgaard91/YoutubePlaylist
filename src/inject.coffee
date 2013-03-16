player = null
prevState = null
onUnstarted = () ->
	console.log 'unstarted'

onEnded = () ->
	debugger

onPlaying = () ->
	console.log "playing: #{player.getCurrentTime()}"

onPaused = () ->
	console.log 'paused'

onBuffering = () ->
	console.log 'buffering'

onVideoCued = () ->
	console.log 'video cued'

onYouTubePlayerReady = (playerId) ->
	player = document.getElementById 'movie_player'	
	
	setInterval () ->
		state = player.getPlayerState()
		return if state is prevState
		prevState = state
		switch state
			when -1 then onUnstarted()
			when 0 then onEnded()
			when 1 then onPlaying()
			when 2 then onPaused()
			when 3 then onBuffering()
			when 5 then onVideoCued()
	, 1000
