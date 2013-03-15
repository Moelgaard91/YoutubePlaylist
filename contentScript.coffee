console.log "contentScript loaded"
console.log "document state: " + document.readyState
console.log chrome

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
console.log "player loaded, name: " + player.name

niels = () ->
	console.log 'state changed. New state: ' + state

#player.addEventListener "onStateChange", "niels"

console.log 'event should be added now, boss..'
#do player.stopVideo

chrome.extension.sendMessage 'Greetings'
console.log 'greeting sent'

chrome.extension.onMessage.addListener (request, sender) ->
	console.log 'Message received: ' + request
	console.log 'sender.tab.url: ' + sender.tab.url

	return unless request?
	switch request
		when 'stop' then do @player.stopVideo + console.log 'player stopped.'
		when 'play' then do @player.playVideo + console.log 'player started.'
		#when 'play' then @player.playVideo
		else console.error "unknown action: #{request.action}"

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
