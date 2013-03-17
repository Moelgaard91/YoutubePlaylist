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
	# @var boolean
	###
	playing : null

	###
	# @var integer
	###
	tabId   : null

	###
	# @var string
	###
	title   : null

	###
	# Constructs a video object
	# @param object
	###
	constructor: (obj) ->
		_(@).extend obj

	###
	# Sets the playing state of the video.
	# @param boolean state
	# @return void
	# @event change:playing
	###
	setPlaying: (state) ->
		@playing = state
		@publishEvent 'change:playing', state

	###
	# Sets the title of the video
	# @param string title
	# @return void
	# @event change:title
	###
	setTitle: (title) ->
		@title = title
		@publishEvent 'change:title', title