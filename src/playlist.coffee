Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class Playlist

	list: {}
	priority: []
	current: null
	port: null

	#constructor: (@port) ->

	#chrome.extension.onConnect.addListener (port) ->
	#	console.log 'connection established from ' + port.name
	#	@port = port
	#	#port.postMessage('stop');

	#	@port.onMessage.addListener (msg) ->
	#		console.log 'playlist received message: ' + msg

	#	@port.postMessage 'Greetings.'
	#	@port.postMessage 'stop'

	addVideo: (tabId, title, callback) ->
		console.log '[playlist] Video added'
		videoObject =
			playing: false
			tabId: tabId
			title: title
		@list[tabId] = videoObject
		@priority.push tabId
		callback? videoObject

	removeVideo: (tabId, callback) ->
		delete @list[tabId] if @list[tabId]?
		@priority.remove tabId
		callback?()

	playVideo: (tabId, callback) ->
		return callback?() if do @isPlaying

		@getTab tabId, (tab) =>
			@port.postMessage action: "play"
			callback?()
			# chrome.tabs.executeScript tabId, 
			# 	code: """
			# 		var player = document.getElementById('movie_player');
			# 		player.playVideo();
			# 	"""
			# , (res) =>
			# 	@list[tabId].playing = true
			# 	@current = @list[tabId]
			# 	callback?()

	stopVideo: (tabId, callback) ->
		sendMsg tabId, 'stop'
		@list[tabId].playing = false
		@current = null if @current and @current.tabId is @list[tabId].tabId


		#@getTab tabId, (tab) =>
			# console.log tab
			# chrome.tabs.executeScript tabId, 
			# 	code: """
			# 		var player = document.getElementById('movie_player');
			# 		player.stopVideo();
			# 	"""
			# , (res) =>
			# 	@list[tabId].playing = false
			# 	@current = null
			# 	console.log res
			# 	callback?()

	getTab: (tabId, callback) ->
		chrome.tabs.get tabId, (tab) ->
			throw new Error "tab not found: #{tabId}" unless 	tab?
			callback tab

	isPlaying: () ->
		for data of @list
			return yes if data.playing
		return no

	playNext: (callback) ->
		chrome.tabs.remove @current.tabId, () =>
			nextId = @priority[0]
			playVideo nextId, callback

	getList: () ->
		@list

	getPriority: () ->
		@priority

	playSong = (priority) ->
		console.log 'alright, playing song ' + priority
		tabId = list[priority].tabId
		list[priority].playing = true
		current = list[priority]
		sendMsg tabId, 'play'

	sendMsg: (tabId, msg) ->
		console.log '[playlist] Sending message: ' + msg + ' to tabId: ' + tabId
		chrome.tabs.sendMessage tabId, msg