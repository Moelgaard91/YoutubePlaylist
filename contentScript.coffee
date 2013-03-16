console.log "contentScript loaded"
console.log "document state: " + document.readyState
#console.log chrome

#onYoutubePlayerReady() ->
#	console.log 'svend'

#actualCode = ['console.log("torsten!");'].join '\n'

#s = document.createElement('script')
#s.textContext = actualCode

#(document.head || document.documentElement).appendChild s
#s.parentNode.removeChild s

#actualCode = ['console.log("this should be from an injected script");',
#							'var player = document.getElementById("movie_player");',
#							'var state = player.getPlayerState();',
#							'console.log(state);'].join '\n'

#s = document.createElement('script')
#s.textContext = actualCode
#(document.head || document.documentElement).appendChild s
#s.parentNode.removeChild s


#s.textContext = 
#s.onLoad = () ->
#	player = document.getElementById('movie_player')
#	player.addEventListener "onStateChanged", () ->
#		console.log 'state changed!!!!'

#document.getElementsByTagName('head')[0].appendChild s

#var s = document.createElement('script');
#s.src = chrome.extension.getURL("script.js");
#s.onload = function() {
    #this.parentNode.removeChild(this);
#};
#(document.head||document.documentElement).appendChild(s);

player = document.getElementById('movie_player')
console.log "player loaded"

initListeners = () ->

	player.addEventListener 'click', (e) ->
		debugger

	chrome.extension.sendMessage 'Greetings'

	chrome.extension.onMessage.addListener (request, sender) ->
		console.log 'Message received: ' + request
		console.log 'sender.tab.url: ' + sender.tab.url
		return unless request?
		switch request
			when 'stop' then do player.stopVideo
			when 'play' then do player.playVideo
			else console.error "unknown action: #{request.action}"

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

injectJs = (link) ->
	console.log "injecting: #{link} into the site"
	scr = document.createElement 'script'
	scr.type = 'text/javascript'
	scr.src = link
	(document.head or document.body or document.documentElement).appendChild scr

injectJs chrome.extension.getURL 'inject.js'

#port = chrome.extension.connect name: "playlist"

#port.postMessage 'Why, hello there!'

#port.onConnect.addEventListener () ->
#	console.log 'niels'

#port.onMessage.addListener (msg) ->
#	console.log 'contentScript received message: ' + msg

#	return unless msg?
#	switch msg
		#when 'stop' then do @player.stopVideo
		#when 'stop' then console.log 'player state: ' + @player.getPlayerState()
#		when 'stop' then do @player.stopVideo
#		else console.error "unknown action: #{msg.action}"
	#return unless msg.action?
	#switch msg.action
	#	when 'play' then do player.playVideo
	#	when 'stop' then do player.stopVideo
	#	else console.error "unknown action: #{msg.action}"

#player.addEventListener "onStateChange", (state) ->
#	console.log "playing next.."
#	port.postMessage state: state
