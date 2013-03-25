# This is for testing purposes only.
if require?
	_ = require 'underscore'
	{Event} = require './event'

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
	# @var object id: Video
	###
	list: {}
	
	###
	# @var array id
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
	# @return string
	###
	getNextId: () -> _.uniqueId 'video'

	###
	# Adds a video in paused mode, to the playlist
	# @param Tab tab
	# @param [ function callback ] (err, video)
	# @return void
	# @event add:video (video), update:video (video)
	###
	addVideo: (tab, callback) ->
		return callback? msg: "The tab cannot be empty" unless tab?
		# update the video, if we already no the video.
		return @updateVideo video, tab, callback if (video = @getVideoByTab tab)?
	
		# create new video object.
		video = @createVideo tab

		# keep the lists updated.
		@pushToList video
		
		# check if we have too many tabs opened.
		if @length > @maxOpenVideoTabs
			# sets state to pending, and remove the tab.
			@pendVideo video, (err, video) ->
				console.error "addVideo: Couldn't set video pending", err, video if err?

		callback? null, video
		@publishEvent 'add:video', video

	###
	# Create a video.
	# @param Tab tab
	# @return Video
	###
	createVideo: (tab) ->
		new Video
			id: @getNextId()
			playing: false
			tab: tab
			title: tab.title
			videoUrl: tab.url
			pending: false

	###
	# Update info on a video object, with new info from a tab.
	# @param Video video
	# @param Tab tab
	# @param [ function callback ] (err)
	# @return void
	# @event update:video (video)
	###
	updateVideo: (video, tab, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		# no need to fire an update event, when a tab comes in with the same url,
		# it properly has the same url, because the tab was just restored.
		return callback? null, video if video.videoUrl is tab.url
		
		# update the properties.
		video.setTitle tab.title
		video.setVideoUrl tab.url

		callback? null, video
		@publishEvent 'update:video', video

	###
	# Removes a video from the playlist.
	# @param Video video
	# @param [ function callback ] (err, video)
	# @return void
	# @event add:video (video)
	###
	removeVideo: (video, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		# keep lists upteded.		
		@listRemove video

		# restore a tab, if there is any to restore.
		if @length >= @maxOpenVideoTabs
			v = @list[@priority[@maxOpenVideoTabs-1]]
			@restoreVideo v if v.pending

		callback? null, video
		@publishEvent 'remove:video', video

	###
	# Play video - sends a play event to the video player of the id.
	# @param Video video
	# @param [ function callback ] (err)
	# @return void
	# @event start:video (video)
	###
	playVideo: (video, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		# send the play message to tab's content script.
		@sendMsg video, 'play'

		callback? null
		@publishEvent 'start:video', video

	###
	# Stop video - sends a stop event to the video player.
	# @param Video video
	# @param [ function callback ] (err, res)
	# @event pause:video (video)
	###
	stopVideo: (video, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		# NB! this should never happen.
		return callback? msg: "The video is pending state: so there is no video to stop", video if video.pending
		
		# send stop event to content script.
		@sendMsg video, 'stop', callback

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
			return @removeVideo @current, (err, video) ->
				console.error "playNext: Couldn't remove video", err, video if err?

		# get the current tab, to determine, if it is active
		chrome.tabs.get @current.tab.id, (tab) =>
			# return if the tab couldn't be found.
			return callback? msg: "Tab not found: #{@current.tab.Id}" unless tab?
			# save the select state for the tab.
			isActive = tab.selected
			
			# removing the tab of the newly finished video.
			chrome.tabs.remove @current.tab.id, () =>
				nextVideo = @list[nextId]
				return callback? msg: "The next video wasn't found, id: #{nextId}" unless nextVideo?

				# play the next video
				@playVideo nextVideo, () =>
					if isActive
						@activateTab nextVideo, (err, video, tab) ->
							console.error "playNext: Couldn't activate tab", err if err?
					
					# check if there are videos beyond the max limit.
					if @length > @maxOpenVideoTabs
						# get the video just beyond the limit.
						video = @list[@priority[@maxOpenVideoTabs]]
						# create tab if the tab is pending.
						if video.pending
							@restoreVideo video, { windowId: tab.windowId }, (err, video, tab) ->
								console.error "playNext: Couldn't restore video", err, video, tab if err?

					return callback? null, nextVideo

	###
	# Activate the tab corresponding to the id.
	# @param Video video
	# @param [ function callback ] (err, video, tab)
	# @return void
	###
	activateTab: (video, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		unless video.pending
			chrome.tabs.update video.tab.id, { selected: true }, (tab) ->
				callback? null, video, tab
		# create tab if the video is in pending mode.
		else
			@createTab video, { windowId: @current.tab.windowId }, callback

	###
	# Create a tab based on a video id.
	# @param Video video
	# @param [ object createTabOptions ] The options passed along to the chrome.tabs.create
	# @param function callback (err, video, tab)
	# @return void
	###
	createTab: (video, createTabOptions, callback) ->
		return callback? msg: "The video cannot be empty" unless video?

		if _.isFunction createTabOptions
			callback = createTabOptions
			createTabOptions = {}

		return console.error "A callback has to be defined in create tab" unless _.isFunction callback

		options =
			index: 999
			url: video.videoUrl
			active: false

		_.extend options, createTabOptions

		chrome.tabs.create options, (tab) ->
			callback null, video, tab

	###
	# Move a video to a new index in the priority.
	# @param Video video
	# @param integer newIndex
	# @param [ function callback ] (err, priorityList)
	# @return void
	# @event move:video (video, index, priorityList)
	###
	moveVideo: (video, newIndex, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		return callback? msg: "The new index has to be greater than 0, got: #{newIndex}", @priority if newIndex < 0
		return callback? msg: "Index out of bounce, max index: #{maxIndex}", @priority              if newIndex > (maxIndex = @length.length - 1)
		return callback? msg: "The id doesn't exist in the playlist priority: #{id}", @priority     if (oldIndex = _.indexOf @priority, video.id) is -1

		# move elements in array magic.
		if newIndex >= @priority.length
			k = newIndex - @priority.length
			while (k--) + 1
				@priority.push undefined
		@priority.splice newIndex, 0, (@priority.splice oldIndex, 1)[0]
		
		# handle moving from pending to non pending.
		if oldIndex >= @maxOpenVideoTabs and newIndex < @maxOpenVideoTabs
		
			# restore the moved video.
			@restoreVideo video, (err, video) ->
				console.error "moveVideo: Couldn't restore video", err, video if err?

			# set the video which stepped over the limit to pending.
			@pendVideo @list[@priority[@maxOpenVideoTabs]], (err, video) ->
				console.error "moveVideo: Couldn't set video pending", err, video if err?
		
		# handle moving from non pending to pending.
		else if oldIndex < @maxOpenVideoTabs and newIndex >= @maxOpenVideoTabs
		
			# the video which is now inside the limit
			@restoreVideo @list[@priority[@maxOpenVideoTabs-1]], (err, video) ->
				console.error "moveVideo: Couldn't restore video", err, video if err?
		
			# set the moved video to pending.
			@pendVideo video, (err, video) ->
				console.error "moveVideo: Couldn't set video pending", err, video if err?

		callback? null, @priority
		@publishEvent 'move:video', video, newIndex, @priority

	###
	# Restore pending video.
	# @param Video video
	# @param [ object createTabOptions ] if no createTabOptions is provided, then @current.tab.windowId is send as tabOptions.
	# @param [ function callback ] (err, video, tab)
	# @return void
	###
	restoreVideo: (video, createTabOptions, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		# the callback can also be provided instead of 
		if _.isFunction createTabOptions
			callback = createTabOptions
			createTabOptions = null

		return callback? msg: "The video is not pending", video unless video.pending
		
		create = (video, createTabOptions, callback) ->
			@createTab video, createTabOptions, (err, video, tab) ->
				return callback? err if err?
				video.setTab tab
				video.setPending no
				callback? null, video, tab

		if createTabOptions?
			create.call @, video, createTabOptions, callback
		else
			create.call @, video, { windowId: @current.tab.windowId }, callback
			

	###
	# Set a video to pending, which means removing the tab as well.
	# @param Video video
	# @param [ function callback ] (err, video)
	# @return void
	###
	pendVideo: (video, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		return callback? msg: "The video is already pending", video if video.pending
		video.setPending yes
		chrome.tabs.remove video.tab.id, () ->
			callback? null

	###
	# Set the state of a tab to be playing, this is used when a user manually has started a video,
	# this is called to keep track of the state internally.
	# @param Video video
	# @return void
	# @event start:video (video)
	###
	setPlaying: (video) ->
		return callback? msg: "The video cannot be empty" unless video?
		
		# stop the video if the current tab isn't our selves.
		if @current? and @current.tab.id isnt video.tab.id
			@stopVideo @current, (err, video) ->
				console.error "setPlaying: Couldn't stop video", err, video if err?
		
		# move the video to index 0, if it isn't already there.
		if video.tab.id isnt @list[@priority[0]].tab.id
			@moveVideo video, 0, (err, video) ->
				console.error "setPlaying: Couldn't move video", err, video if err?
		
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
	# @param Video video
	# @return void
	# @event pause:video (video)
	###
	setPaused: (video) ->
		return callback? msg: "The video cannot be empty" unless video?
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
	pushToList: (video) ->
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
	# @return array<string>
	###
	getPriority: () -> @priority

	###
	# Get video by tab.
	# @param Tab|integer tab
	# @param [ boolean byId = false ]
	# @return Video|null
	###
	getVideoByTab: (tab, byId = false) ->
		for k, v of @list
			if byId
				return v if v.tab.id is tab
			else
				return v if v.tab.id is tab.id
		return null

	###
	# Send a message to a tab.
	# @param Video video
	# @param mixed msg
	# @param [ function callback ] (err, ...)
	# @return void
	###
	sendMsg: (video, msg, callback) ->
		return callback? msg: "The video cannot be empty" unless video?
		chrome.tabs.sendMessage video.tab.id, msg, () ->
			callback? null, arguments...

# This is for testing purposes only.
exports?.Playlist = Playlist