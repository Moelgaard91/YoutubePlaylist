###
# The actual playlist.
# @author thetrompf
# @author Moelgaard91
###
class Playlist

	###
	# @mixin Event
	###
	_(@prototype).extend Event.prototype

	###
	# @var object tabId: Video
	###
	list     : {}
	
	###
	# @var array tabIds
	###
	priority : []

	###
	# @var Video current video object
	###
	current  : null

	###
	# Adds a video in paused mode, to the playlist
	# @param integer tabId
	# @param string title
	# @param [function callback] (err, video)
	# @return void
	# @event add:video
	###
	addVideo: (tabId, title, callback) ->
		err = null
		if (video = @list[tabId])?
			video.setPlaying false
			video.setTitle title
			callback? err, video
		else
			video = new Video playing: false, tabId: tabId, title: title
			@list[tabId] = video
			@priority.push tabId

			callback? err, video
			@publishEvent 'add:video', tabId, video

	###
	# Removes a video from the playlist
	# @param integer tabId
	# @param [function callback] (err)
	# @return void
	# @event add:video
	###
	removeVideo: (tabId, callback) ->
		err = null
		delete @list[tabId] if @list[tabId]?
		@priority.remove tabId
		callback? err
		@publishEvent 'remove:video', tabId

	###
	# Play video - sends a play event to the video player of the tabId
	# @param integer tabId
	# @param [function callback] (err, response)
	# @return void
	# @event start:video
	###
	playVideo: (tabId, callback) ->
		sendMsg tabId, 'play', callback
		@publishEvent 'start:video', tabId

	###
	# Stop video - sends a stop event to the video player of the tabId
	# @param integer tabId
	# @param [function callback](err, res)
	# @event pause:video
	###
	stopVideo: (tabId, callback) ->
		err = null
		sendMsg tabId, 'stop'
		return callback? msg: "There is no video on tabId: #{tabId}" unless (video = @list[tabId])?
		video.setPlaying false
		@current = null if @current and @current.tabId is video.tabId
		@publishEvent 'pause:video', tabId
		callback? err

	###
	# Get tab by id
	# @param integer tabId
	# @param function callback (err, tab)
	# @return void
	###
	getTab: (tabId, callback) ->
		err = null
		chrome.tabs.get tabId, (tab) ->
			callback msg: "Tab not found: #{tabId}" unless tab?
			callback err, tab

	###
	# Whether there is a video in the playlist that is playing.
	# @return boolean
	###
	isPlaying: () ->
		for data of @list
			return yes if data.playing
		return no

	###
	# Play the next video in the playlist.
	# @param [function callback] (err)
	# @return void
	###
	playNext: (callback) ->
		currentId = @current.tabId
		nextId = @priority[1]
		chrome.tabs.get currentId, (tab) =>
			return callback? msg: "Tab not found: #{currentId}" unless tab?
			isActive = tab.selected
			chrome.tabs.remove currentId, () =>
				@playVideo nextId, callback if nextId?
				if isActive
					chrome.tabs.update nextId, selected: true
				return callback?()

	###
	# Set the state of a tab to be playing, this is used when a user manually has started a video,
	# this is called to keep track of the state internally.
	# @param integer tabId
	# @return void
	# @event start:video
	###
	setPlaying: (tabId) ->
		@stopVideo @current.tabId if @current? and @current.tabId isnt tabId
		@current = @list[tabId]
		@list[tabId].setPlaying true
		@publishEvent 'start:video', tabId

	###
	# Set the state of a tab to be paused, this is used when a user manually has paused a video,
	# this is called to keep track of the state internally.
	# @param interger tabId
	# @return void
	# @event pause:video
	###
	setPaused: (tabId) ->
		if (video = @list[tabId])?
			video.setPlaying false
			@publishEvent 'pause:video', tabId

	###
	# Get the internal list.
	# @return object { tabId: Video }
	###
	getList: () ->
		@list

	###
	# Get the priority list, which contains an array of tabIds,
	# in the order of when they should be played, index 0 is the currently playing
	# index 1 is the next video.
	# @return array<integer>
	###
	getPriority: () ->
		@priority

	###
	# Send a message to a tab.
	# @param integer tabId
	# @param mixed msg
	# @param [function callback] (err, ...)
	# @return void
	###
	sendMsg: (tabId, msg, callback) ->
		chrome.tabs.sendMessage tabId, msg, () ->
			callback? null, arguments...