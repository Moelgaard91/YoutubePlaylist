Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

###
# The event mixin, enables other classes to publish events,
# and let others subscribe to them.
# @author thetrompf
# @author Moelgaard91
###
class Event

	###
	# @var object { event: function[] }
	###
	_events: {}

	###
	# Publish event.
	# @param string event
	# @param mixed data...
	# @return void
	###
	publishEvent: (event, data...) ->
		callbacks = @_events[event]
		return unless callbacks?
		for cb in callbacks
			cb.apply @, data

	###
	# Subscribe to an event.
	# @param string event
	# @param function callback
	# @return void
	###
	subscribeEvent: (event, callback) ->
		@_events[event] = [] unless @_events[event]?
		@_events[event].push callback

	###
	# Unsubscribe from an event
	# @param string event
	# @param function callback
	# @return void
	###
	unsubscribeEvent: (event, callback) ->
		if @_events[event]?
			@_events[event].remove callback
			delete @_events[event] if @_events[event].length is 0

# This is for testing purposes only.
exports?.Event = Event