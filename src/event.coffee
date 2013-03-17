Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class Event

	_events: {}

	publishEvent: (event, data) ->
		callbacks = @_events[event]
		return unless callbacks?
		for cb in callbacks
			cb data

	subscribeEvent: (event, callback) ->
		@_events[event] = [] unless @_events[event]?
		@_events[event].push callback

	unsubscribeEvent: (event, callback) ->
		@_events[event].remove callback if @_events[event]?.remove?