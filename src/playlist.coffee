class Playlist

	_(@prototype).extend Event.prototype

	list     : {}
	priority : []
	current  : null

	addVideo: (tabId, title, callback) ->
		if (v = @list[tabId])?
			v.setPlaying false
			v.setTitle title
			callback? v
		else
			v = new Video playing: false, tabId: tabId, title: title
			@list[tabId] = v
			@priority.push tabId

			callback? v
			@publishEvent 'add:video', tabId, v

	removeVideo: (tabId, callback) ->
		delete @list[tabId] if @list[tabId]?
		@priority.remove tabId
		callback?()
		@publishEvent 'remove:video', tabId

	playVideo: (tabId, callback) ->
		return callback?() if @isPlaying()
		@getTab tabId, (tab) =>
			sendMsg tabId, 'play'
			callback?()
			@publishEvent 'start:video', tabId

	stopVideo: (tabId, callback) ->
		sendMsg tabId, 'stop'
		@list[tabId].setPlaying false
		@current = null if @current and @current.tabId is @list[tabId].tabId
		@publishEvent 'pause:video', tabId

	getTab: (tabId, callback) ->
		chrome.tabs.get tabId, (tab) ->
			throw new Error "tab not found: #{tabId}" unless 	tab?
			callback tab

	isPlaying: () ->
		for data of @list
			return yes if data.playing
		return no

	playNext: (callback) ->
		currentId = @current.tabId
		nextId = @priority[1]
		chrome.tabs.get currentId, (tab) =>
			isActive = tab.selected
			chrome.tabs.remove currentId, () =>
				@playVideo nextId, callback if nextId?
				if isActive
					chrome.tabs.update nextId, selected: true

	setPlaying: (tabId) ->
		unless @isPlaying()
			@current = @list[tabId]
			@list[tabId].setPlaying true
			@publishEvent 'start:video', tabId

	setPaused: (tabId) ->
		if @isPlaying() and (v = @list[tabId])?
			v.playing = false
			@publishEvent 'pause:video', tabId
			@list[tabId].playing = true

	setPaused: () ->
		@current.playing = false if @current?

	getList: () ->
		@list

	getPriority: () ->
		@priority

	sendMsg: (tabId, msg) ->
		chrome.tabs.sendMessage tabId, msg