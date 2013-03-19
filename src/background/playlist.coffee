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
	# @var Video currently selected video object
	###
	current  : null

	###
	# @var integer the length of the playlist
	###
	length: 0

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
			@length = @priority.length
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
		@length = @priority.length
		callback? err
		@publishEvent 'remove:video', video

	###
	# Play video - sends a play event to the video player of the tabId
	# @param integer tabId
	# @param [function callback] (err)
	# @return void
	# @event start:video
	###
	playVideo: (tabId, callback) ->
		callback msg: "The is no video on tabId: #{tabId}" unless (video = @list[tabId])?
		@sendMsg tabId, 'play'
		callback? null
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
	# Whether there is a video in the playlist that is playing.
	# @return boolean
	###
	isPlaying: () -> _.any @list, (e) -> e.playing

	###
	# Play the next video in the playlist.
	# @param [function callback] (err)
	# @return void
	###
	playNext: (callback) ->
		currentId = @current.tabId
		nextId = @priority[1]
		# returns if there is no next video.
		return unless nextId?
		chrome.tabs.get currentId, (tab) =>
			# return if the tab couldn't be found.
			return callback? msg: "Tab not found: #{currentId}" unless tab?
			# save the select state for the tab.
			isActive = tab.selected
			# removing the tab of the newly finished video.
			chrome.tabs.remove currentId, () =>
				# play the next video
				@playVideo nextId, () ->
					if isActive
						chrome.tabs.update nextId, selected: true
					return callback? null

	###
	# Move a video to a new index in the priority
	# @param integer tabId
	# @param integer newIndex
	# @param [ function callback ] (err, priorityList)
	# @return void
	###
	moveVideo: (tabId, newIndex, callback) ->
		if newIndex < 0
			return callback? msg: "The new index has to be greater than 0, got: #{newIndex}", @priority
		
		if newIndex > (maxIndex = @length.length - 1)
			return callback? msg: "Index out of bounce, max index: #{maxIndex}", @priority
		
		if (oldIndex = _.indexOf @priority, tabId) is -1
			return callback? msg: "The tabId doesn't exist in the playlist priority: #{tabId}", @priority

		if newIndex >= @priority.length
			k = newIndex - @priority.length
			while (k--) + 1
				@priority.push undefined
		@priority.splice newIndex, 0, (@priority.splice oldIndex, 1)[0]
		callback? null, @priority
		@publishEvent 'move:video', @priority

	###
	# Set the state of a tab to be playing, this is used when a user manually has started a video,
	# this is called to keep track of the state internally.
	# @param integer tabId
	# @return void
	# @event start:video
	###
	setPlaying: (tabId) ->
		return unless (video = @list[tabId])?
		
		if @current? and @current.tabId isnt tabId
			@stopVideo @current.tabId
		
		if tabId isnt @priority[0]
			@moveVideo tabId, 0
		
		@current = video
		wasPlaying = video.playing

		unless wasPlaying
			video.setPlaying true
			@publishEvent 'start:video', video

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
	getList: () -> @list

	###
	# Get the priority list, which contains an array of tabIds,
	# in the order of when they should be played, index 0 is the currently playing
	# index 1 is the next video.
	# @return array<integer>
	###
	getPriority: () -> @priority

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