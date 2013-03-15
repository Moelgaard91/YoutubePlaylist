playlist = null

playlist = new Playlist()

stopVideo = () ->
	chrome.tabs.executeScript null,
		code: """
		var player = document.getElementById('movie_player');
		player.stopVideo();
		console.log(player);
		"""
	, (result) -> console.log result

#chrome.webNavigation.onCompleted.addListener (details) ->
#	chrome.tabs.executeScript null,
#		code: """
#			document.getElementById('movie_player').addEventListener("onStateChange", function(state) {
#				console.log('state changed: ' + state);
##		"""
	#	(result) -> console.log result
	
	#	@playlist.addVideo details.tabId, () -> @playlist.stopVideo details.tabId
	#,
	#	url: [
	#		hostSuffix: "youtube.com"
	#		pathEquals: "/watch"
	#	]

chrome.tabs.onRemoved.addListener (tabId) ->
	playlist.removeVideo tabId, () -> console.log do playlist.getList


chrome.extension.onMessage.addListener (request, sender) ->

	return unless request?

	console.log 'Message received: ' + request + ', tabid: ' + sender.tab.id
	console.log 'sender.tab.url: ' + sender.tab.url
	
	switch request
		when 'Greetings' then do @playlist.addVideo sender.tab.id, sender.tab.title,  () -> @playlist.stopVideo sender.tab.id #chrome.tabs.executeScript sender.tab.id, {code:"console.log('niels!!!'); console.log('karsten!'); var player = document.getElementById('movie_player'); console.log(player); console.log(player.getPlayerState()); player.addEventListener('onStateChange', 'console.log(2+2)');"} 
		when 'Statechange' then do console.log 'niels'
		else console.error "unknown action: #{request.action}"

	#chrome.tabs.sendMessage sender.tab.id, 'Greetings'
	#chrome.tabs.sendMessage sender.tab.id, 'stop'

sendMsg = (tabId, msg) ->
	chrome.tabs.sendMessage tabId, msg

niels = () ->
	alert('niels')

getPlaylist = () ->
	return playlist.getList()

getPriority = () ->
	return playlist.getPriority()

playSong = (priority) ->
	console.log 'playing song with priority: ' + priority

#chrome.extension.onConnect.addListener (port) ->
#	#console.assert port.name is "playlist"
#	console.log 'main - connection established'
#	port.postMessage('Greetings from main')
#	port.postMessage('stop')
#	#playlist = new playlist port
#	#port.onMessage.addListener (msg) ->
#	#	playlist.playNext() if msg.state is 0