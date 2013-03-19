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
	# @var integer|null
	###
	tabId: null

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
	# @param object
	###
	constructor: (obj) ->
		_(@).extend obj

	###
	# Sets the playing state of the video.
	# @param boolean playing
	# @return void
	# @event change:playing
	###
	setPlaying: (playing) ->
		return if playing is @playing
		@playing = playing
		@publishEvent 'change:playing', playing

	###
	# Sets the title of the video
	# @param string title
	# @return void
	# @event change:title
	###
	setTitle: (title) ->
		return if title is @title
		@title = title
		@publishEvent 'change:title', title

	###
	# Sets the video url.
	# @param string videoUrl
	# @return void
	# @event change:videoUrl
	###
	setVideoUrl: (videoUrl) ->
		return if videoUrl is @videoUrl
		@videoUrl = videoUrl
		@publishEvent 'change:videoUrl', videoUrl

	###
	# Sets the pending state of the video.
	# @param boolean pending
	# @return void
	# @event change:pending
	###
	setPending: (pending) ->
		return if pending is @pending
		@pending = pending
		@publishEvent 'change:pending', pending

	###
	# Sets the tabId of the video.
	# @param integer tabId
	# @return void
	# @event change:tabId
	###
	setTabId: (tabId) ->
		return if tabId is @tabId
		@tabId = tabId
		@publishEvent 'change:tabId', tabId

	###
	# Get the formatted title, Foo Fighters - The Pretender - Youtube
	# becomes: Foo Fighters - The Pretender
	# @return string
	###
	getFormattedTitle: () ->
		youtubeString = " - YouTube"
		return @title if @title.length < youtubeString.length
		return @title.substring 0, (@title.length - youtubeString.length)

	###
	# Return whether a video has a tab.
	# @return boolean
	###
	hasTab: () -> @tabId?