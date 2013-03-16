class Video
	
	_(@prototype).extend Event.prototype

	playing : null
	tabId   : null
	title   : null

	constructor: (obj) ->
		_(@).extend obj

	setPlaying: (state) ->
		@playing = state
		@publishEvent 'change:state', state

	setTitle: (title) ->
		@title = title
		@publishEvent 'change:title', title