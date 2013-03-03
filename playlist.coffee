Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class Playlist

	list: {}
	priority: []
	current: null
	port: null

	constructor: (@port) ->

	addVideo: (tabId, callback) ->
		videoObject =
			playing: false
			tabId: tabId
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
		@getTab tabId, (tab) =>
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