# This is for testing purposes only.
if require?
	_ = require 'underscore'
	{Event} = require './event'

###
# The video class, used by playlist.
# @author thetrompf
# @author Moelgaard91
###
class Video
	
	###
	# @mixin Event
	###
	_(@prototype).extend Event.prototype

	###
	# @var integer
	###
	id: null

	###
	# @var string
	###
	videoUrl: null

	###
	# @var boolean
	###
	playing: null

	###
	# It is not a given that a video has been assigned to a tab yet.
	# @var Tab|null
	###
	tab: null

	###
	# @var string
	###
	title: null

	###
	# If the video priority is beyond the maxOpenedVideoTabs limit
	# it becomes pending, which means it doesn't have a tab.
	# @var boolean
	###
	pending: null

	###
	# Constructs a video object
	# @param object obj A hash of the properties you want to set on the video object.
	###
	constructor: (obj) ->
		_(@).extend obj

	###
	# Sets the playing state of the video.
	# @param boolean playing
	# @return void
	# @event change:playing (playing)
	###
	setPlaying: (playing) ->
		return if playing is @playing
		@playing = playing
		@publishEvent 'change:playing', playing

	###
	# Sets the title of the video
	# @param string title
	# @return void
	# @event change:title (title)
	###
	setTitle: (title) ->
		return if title is @title
		@title = title
		@publishEvent 'change:title', title

	###
	# Sets the video url.
	# @param string videoUrl
	# @return void
	# @event change:videoUrl (videoUrl)
	###
	setVideoUrl: (videoUrl) ->
		return if videoUrl is @videoUrl
		@videoUrl = videoUrl
		@publishEvent 'change:videoUrl', videoUrl

	###
	# Sets the pending state of the video.
	# @param boolean pending
	# @return void
	# @event change:pending (pending)
	###
	setPending: (pending) ->
		return if pending is @pending
		@pending = pending
		@publishEvent 'change:pending', pending

	###
	# Sets the tab of the video.
	# @param Tab|null tab
	# @return void
	# @event change:tab (tab)
	###
	setTab: (tab) ->
		return if not tab? and not @tab?
		return if tab?.id is @tab?.id
		@tab = tab
		@publishEvent 'change:tab', tab

	###
	# Get the formatted title, Foo Fighters - The Pretender - Youtube
	# becomes: Foo Fighters - The Pretender
	# @return string
	###
	getFormattedTitle: () ->
		youtubeString = " - YouTube"
		return @title if (i = @title.lastIndexOf youtubeString) is -1
		return @title.substring 0, i

	###
	# Return whether a video has a tab.
	# @return boolean
	###
	hasTab: () -> @tab?

# This is for testing purposes only.
exports?.Video = Video