playlist = null

stopVideo = () ->
	chrome.tabs.executeScript null,
		code: """
		var player = document.getElementById('movie_player');
		player.stopVideo();
		console.log(player);
		"""
	, (result) -> console.log result

chrome.webNavigation.onCompleted.addListener (details) ->
	playlist.addVideo details.tabId, () -> playlist.stopVideo details.tabId
,
	url: [
		hostSuffix: "youtube.com"
		pathEquals: "/watch"
	]

chrome.tabs.onRemoved.addListener (tabId) ->
	playlist.removeVideo tabId, () -> console.log do playlist.getList

chrome.extension.onConnect.addListener (port) ->
	console.assert port.name is "playlist"
	playlist = new playlist port
	port.onMessage.addListener (msg) ->
		playlist.playNext() if msg.state is 0