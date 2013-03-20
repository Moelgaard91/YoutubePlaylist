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
	# @var integer id counter
	###
	idCounter: 0

	###
	# @var object id: Video
	###
	list: {}
	
	###
	# @var array tabIds
	###
	priority: []

	###
	# @var Video currently selected video object
	###
	current: null

	###
	# @var integer the length of the playlist
	###
	length: 0

	###
	# @var integer The amount of open video tabs.
	###
	maxOpenVideoTabs: 5

	###
	# Get the next unique id.
	# @return integer
	###
	getNextId: () -> @idCounter++

	###
	# Adds a video in paused mode, to the playlist
	# @param Tab tab
	# @param [ function callback ] (err, video)
	# @return void
	# @event add:video, update:video
	###
	addVideo: (tab, callback) ->
		err = null
		if (video = @getVideoByTabId tab.id)?
			# update the video, if we already no the video.
			return @updateVideo video.id, tab.title, tab.url, callback
		else
			# create new video object.
			video = new Video id: @getNextId(), playing: false, tabId: tab.id, title: tab.title, videoUrl: tab.url, pending: false

			# keep the lists updated.
			@list[video.id] = video
			@priority.push video.id
			@length = @priority.length
			
			# check if we have too many tabs opened.
			if @length > @maxOpenVideoTabs
				# sets state to pending, and remove the tab.
				video.setPending true
				chrome.tabs.remove tab.id

			callback? err, video
			@publishEvent 'add:video', video

	###
	# @param integer id
	# @param string title
	# @param string videoUrl
	# @param [ function callback ] (err)
	# @return void
	# @event update:video
	###
	updateVideo: (id, title, videoUrl, callback) ->
		return callback? msg: "There is no video with id: #{id}" unless (video = @list[id])?
		# no need to fire an update event, when a tab comes in with the same url,
		# it properly has the same url, because the tab was just restored.
		return callback? null, video if video.videoUrl is videoUrl
		
		# update the properties.
		video.setTitle title
		video.setVideoUrl videoUrl

		callback? null, video
		@publishEvent 'update:video', video

	###
	# Removes a video from the playlist
	# @param integer tabId
	# @param [ function callback ] (err)
	# @return void
	# @event add:video
	###
	removeVideo: (tabId, callback) ->
		# check if we know the video.
		video = @getVideoByTabId tabId
		return callback? msg: "The video doesn't exist" unless video?
		
		# delete the video references.
		delete @list[video.id]
		# keep the lists updated.
		@priority.remove video.id
		@length = @priority.length

		callback? null
		@publishEvent 'remove:video', video

	###
	# Play video - sends a play event to the video player of the id.
	# @param integer id
	# @param [ function callback ] (err)
	# @return void
	# @event start:video
	###
	playVideo: (id, callback) ->
		# check if we know the video.
		callback msg: "The is no video with id: #{id}" unless (video = @list[id])?
		
		# send the play message to tab's content script.
		@sendMsg video.tabId, 'play'

		callback? null
		@publishEvent 'start:video', video

	###
	# Stop video - sends a stop event to the video player of the tabId
	# @param integer id
	# @param [ function callback ] (err, res)
	# @event pause:video
	###
	stopVideo: (id, callback) ->
		# check if we know the video.
		return callback? msg: "There is no video on id: #{id}" unless (video = @list[id])?
		# NB! this should never happen.
		return callback? msg: "The video is pending state: so there is no video to stop" if video.pending
		
		# send stop event to content script.
		@sendMsg video.tabId, 'stop', callback

		# change the video state.
		video.setPlaying false

		@publishEvent 'pause:video', video

	###
	# Whether there is a video in the playlist that is playing.
	# @return boolean
	###
	isPlaying: () -> _.any @list, (e) -> e.playing

	###
	# Play the next video in the playlist.
	# @param [ function callback ] (err, video)
	# @return void
	###
	playNext: (callback) ->
		nextId = @priority[1]
		
		# returns if there is no next video.
		unless nextId?
			return @removeVideo @current.tabId, (err) ->
				console.error err if err?

		# get the current tab, to determine, if it is active
		chrome.tabs.get @current.tabId, (tab) =>
			# return if the tab couldn't be found.
			return callback? msg: "Tab not found: #{@current.tabId}" unless tab?
			# save the select state for the tab.
			isActive = tab.selected
			
			# removing the tab of the newly finished video.
			chrome.tabs.remove @current.tabId, () =>
	
				# play the next video
				@playVideo nextId, () =>
					if isActive
						@activateTab nextId

					# check if there are videos beyond the max limit.
					if @length >= @maxOpenVideoTabs
						# get the video there is right at the limit.
						video = @list[@priority[@maxOpenVideoTabs]]

						# create tab if the tab is pending.
						if video.pending
							@createTab video.id, (err, tab) ->

								# sets the new state and tabId on the restored video.
								video.setTabId tab.id
								video.setPending no

					return callback? null, @list[nextId]

	###
	# Activate the tab corresponding to the id.
	# @param integer id
	# @return void
	###
	activateTab: (id, callback) ->
		return unless (video = @list[id])?
		return chrome.tabs.update video.tabId, { selected: true }, callback unless video.pending
		@createTab id, callback

	###
	# Create a tab based on a video id.
	# @param integer id
	# @param function callback (err, tab)
	# @return void
	###
	createTab: (id, callback) ->
		return callback msg: "There is no video with id: #{id}" unless (video = @list[id])?
		chrome.tabs.create
			index: 999
			url: video.videoUrl
			active: false
		, (tab) ->
			callback null, tab

	###
	# Move a video to a new index in the priority
	# @param integer id
	# @param integer newIndex
	# @param [ function callback ] (err, priorityList)
	# @return void
	###
	moveVideo: (id, newIndex, callback) ->
		if newIndex < 0
			return callback? msg: "The new index has to be greater than 0, got: #{newIndex}", @priority
		
		if newIndex > (maxIndex = @length.length - 1)
			return callback? msg: "Index out of bounce, max index: #{maxIndex}", @priority
		
		if (oldIndex = _.indexOf @priority, id) is -1
			return callback? msg: "The id doesn't exist in the playlist priority: #{id}", @priority

		if newIndex >= @priority.length
			k = newIndex - @priority.length
			while (k--) + 1
				@priority.push undefined
		@priority.splice newIndex, 0, (@priority.splice oldIndex, 1)[0]
		
		if oldIndex > (@maxOpenVideoTabs-1) and newIndex < @maxOpenVideoTabs
			video = @list[id]
			@createTab id, (err, tab) ->
				video.setTabId tab.id
				video.setPending false

			videoTabToRemove = @list[@priority[@maxOpenVideoTabs]]
			videoTabToRemove.setPending yes
			chrome.tabs.remove videoTabToRemove.tabId

		else if oldIndex < @maxOpenVideoTabs and newIndex > (@maxOpenVideoTabs-1)
			videoTabToRestore = @list[@priority[@maxOpenVideoTabs-1]]
			@createTab videoTabToRestore.id, (err, tab) ->
				videoTabToRestore.setTabId tab.id
				videoTabToRestore.setPending false

			video = @list[id]
			video.setPending yes
			chrome.tabs.remove video.tabId

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
		return unless (video = @getVideoByTabId tabId)?
		
		if @current? and @current.tabId isnt tabId
			@stopVideo @current.id
		
		if tabId isnt @list[@priority[0]].tabId
			@moveVideo video.id, 0
		
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
		if (video = @getVideoByTabId tabId)?
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
	# Get video by tabId.
	# @param integer tabId
	# @return Video|null
	###
	getVideoByTabId: (tabId) ->
		for k, v of @list
			return v if v.tabId is tabId
		return null

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