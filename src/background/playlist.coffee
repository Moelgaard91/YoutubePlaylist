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
	# @event add:video, change:video
	###
	addVideo: (tabId, title, callback) ->
		err = null
		if (video = @list[tabId])?
			video.setPlaying false
			video.setTitle title
			callback? err, video
			@publishEvent 'change:video', video
		else
			video = new Video playing: false, tabId: tabId, title: title
			@list[tabId] = video
			@priority.push tabId

			callback? err, video
			@publishEvent 'add:video', video

	###
	# Removes a video from the playlist
	# @param integer tabId
	# @param [function callback] (err)
	# @return void
	# @event add:video
	###
	removeVideo: (tabId, callback) ->
		err = null
		delete @list[tabId] if (video = @list[tabId])?
		@priority.remove tabId
		callback? err
		@publishEvent 'remove:video', video

	###
	# Play video - sends a play event to the video player of the tabId
	# @param integer tabId
	# @param [function callback] (err, response)
	# @return void
	# @event start:video
	###
	playVideo: (tabId, callback) ->
		callback msg: "The is no video on tabId: #{tabId}" unless (video = @list[tabId])?
		@sendMsg tabId, 'play', callback
		@publishEvent 'start:video', video

	###
	# Stop video - sends a stop event to the video player of the tabId
	# @param integer tabId
	# @param [function callback](err, res)
	# @event pause:video
	###
	stopVideo: (tabId, callback) ->
		return callback? msg: "There is no video on tabId: #{tabId}" unless (video = @list[tabId])?
		@sendMsg tabId, 'stop', callback
		video.setPlaying false
		@current = null if @current and @current.tabId is video.tabId
		@publishEvent 'pause:video', video

	###
	# Get tab by id
	# @param integer tabId
	# @param function callback (err, tab)
	# @return void
	###
	getTab: (tabId, callback) ->
		chrome.tabs.get tabId, (tab) ->
			callback msg: "Tab not found: #{tabId}" unless tab?
			callback null, tab

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
				return callback? null

	###
	# Set the state of a tab to be playing, this is used when a user manually has started a video,
	# this is called to keep track of the state internally.
	# @param integer tabId
	# @return void
	# @event start:video
	###
	setPlaying: (tabId) ->
		return unless (video = @list[tabId])?
		@stopVideo @current.tabId if @current? and @current.tabId isnt tabId
		@current = video
		wasPlaying = video.playing
		video.setPlaying true
		@publishEvent 'start:video', video unless wasPlaying

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
			@publishEvent 'pause:video', video

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