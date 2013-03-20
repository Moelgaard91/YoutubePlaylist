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
	# @event add:video (video), update:video (video)
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
			@listPush video
			
			# check if we have too many tabs opened.
			if @length > @maxOpenVideoTabs
				# sets state to pending, and remove the tab.
				@pendVideo video

			callback? err, video
			@publishEvent 'add:video', video

	###
	# @param integer id
	# @param string title
	# @param string videoUrl
	# @param [ function callback ] (err)
	# @return void
	# @event update:video (video)
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
	# @event add:video (video)
	###
	removeVideo: (tabId, callback) ->
		# check if we know the video.
		video = @getVideoByTabId tabId
		return callback? msg: "The video doesn't exist" unless video?
		
		# keep lists upteded.		
		@listRemove video

		# restore a tab, if there is any to restore.
		if @length > @maxOpenVideoTabs
			@restoreVideo @list[@priority[@maxOpenVideoTabs-1]]

		callback? null
		@publishEvent 'remove:video', video

	###
	# Play video - sends a play event to the video player of the id.
	# @param integer id
	# @param [ function callback ] (err)
	# @return void
	# @event start:video (video)
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
	# @event pause:video (video)
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
						# get the video at the limit.
						video = @list[@priority[@maxOpenVideoTabs]]
						# create tab if the tab is pending.
						@restoreVideo video if video.pending

					return callback? null, @list[nextId]

	###
	# Activate the tab corresponding to the id.
	# @param integer id
	# @param [ function callback ] (err)
	# @return void
	###
	activateTab: (id, callback) ->
		return callback? msg: "There is no video with that id found", video: video unless (video = @list[id])?
		# active the tab if its there.
		return chrome.tabs.update video.tabId, { selected: true }, callback unless video.pending
		# create tab if the video is in pending mode.
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
	# @event move:video (video)
	###
	moveVideo: (id, newIndex, callback) ->
		return callback? msg: "The new index has to be greater than 0, got: #{newIndex}", @priority if newIndex < 0
		return callback? msg: "Index out of bounce, max index: #{maxIndex}", @priority              if newIndex > (maxIndex = @length.length - 1)
		return callback? msg: "The id doesn't exist in the playlist priority: #{id}", @priority     if (oldIndex = _.indexOf @priority, id) is -1

		# move elements in array magic.
		if newIndex >= @priority.length
			k = newIndex - @priority.length
			while (k--) + 1
				@priority.push undefined
		@priority.splice newIndex, 0, (@priority.splice oldIndex, 1)[0]
		
		# handle moving from pending to non pending.
		if oldIndex >= @maxOpenVideoTabs and newIndex < @maxOpenVideoTabs
		
			# restore the moved video.
			@restoreVideo @list[id]

			# set the video which stepped over the limit to pending.
			@pendVideo @list[@priority[@maxOpenVideoTabs]]
		
		# handle moving from non pending to pending.
		else if oldIndex < @maxOpenVideoTabs and newIndex >= @maxOpenVideoTabs
		
			# the video which is now inside the limit
			@restoreVideo @list[@priority[@maxOpenVideoTabs-1]]
		
			# set the moved video to pending.
			@pendVideo @list[id]

		callback? null, @priority
		@publishEvent 'move:video', @priority

	###
	# Restore pending video.
	# @param Video video
	# @param [ function callback ] (err, video, tab)
	# @return void
	###
	restoreVideo: (video, callback) ->
		return callback? msg: "The video is not pending", video: video unless video.pending
		@createTab video.id, (err, tab) ->
			return callback? err if err?
			video.setTabId tab.id
			video.setPending false
			callback? null, video, tab

	###
	# Set a video to pending, which means removing the tab as well.
	# @param Video video
	# @param [ function callback ] (err)
	# @return void
	###
	pendVideo: (video, callback) ->
		return callback? msg: "The video is already pending", video: video if video.pending
		video.setPending yes
		chrome.tabs.remove video.tabId, () ->
			callback? null

	###
	# Set the state of a tab to be playing, this is used when a user manually has started a video,
	# this is called to keep track of the state internally.
	# @param integer tabId
	# @return void
	# @event start:video (video)
	###
	setPlaying: (tabId) ->
		# return if the video doesn't exist.
		return unless (video = @getVideoByTabId tabId)?
		
		# stop the video if the current tab isn't our selves.
		if @current? and @current.tabId isnt tabId
			@stopVideo @current.id
		
		# move the video to index 0, if it isn't already there.
		if tabId isnt @list[@priority[0]].tabId
			@moveVideo video.id, 0
		
		# sets current video.
		@current = video
		wasPlaying = video.playing

		# publish event, if state changed
		unless wasPlaying
			video.setPlaying true
			@publishEvent 'start:video', video

	###
	# Set the state of a tab to be paused, this is used when a user manually has paused a video,
	# this is called to keep track of the state internally.
	# @param interger tabId
	# @return void
	# @event pause:video (video)
	###
	setPaused: (tabId) ->
		if (video = @getVideoByTabId tabId)?
			video.setPlaying false
			@publishEvent 'pause:video', video

	###
	# Removes a video from the lists.
	# @param Video video
	# @return void
	###
	listRemove: (video) ->
		# delete the video references.
		delete @list[video.id]
		# keep the lists updated.
		@priority.remove video.id
		@length = @priority.length

	###
	# Push the list
	# @param Video video
	# @return void
	###
	listPush: (video) ->
		@list[video.id] = video
		@priority.push video.id
		@length = @priority.length

	###
	# Get the internal list.
	# @return object { id: Video }
	###
	getList: () -> @list

	###
	# Get the priority list, which contains an array of ids,
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
	# @param [ function callback ] (err, ...)
	# @return void
	###
	sendMsg: (tabId, msg, callback) ->
		chrome.tabs.sendMessage tabId, msg, () ->
			callback? null, arguments...