console.log "contentScript loaded"
player = document.getElementById('movie_player')

port = chrome.extension.connect name: "playlist"

port.onMessage.addEventListener (msg) ->
	console.log msg
	return unless msg.action?
	switch msg.action
		when 'play' then do player.playVideo
		when 'stop' then do player.stopVideo
		else console.error "unknown action: #{msg.action}"

player.addEventListener "onStateChange", (state) ->
	console.log "playing next.."
	port.postMessage state: state
