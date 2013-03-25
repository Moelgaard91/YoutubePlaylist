_ = require 'underscore'
{Event} = require '../src/background/event'

describe 'The internal callback stack in the Event mixin', () ->
	
	beforeEach () ->
		@event = new Event
		@event._events = {}

	it "should grow in the internally _events object, when adding a callback", () ->
		event = 'test:is:happening'
		handler = () ->
		(expect @event._events[event]).toBeUndefined()
		@event.subscribeEvent event, handler
		(expect @event._events[event]).not.toBeUndefined()
		len = @event._events[event].length
		(expect len).toBe 1

	it "and descrease in size, when a callback is unsubscribed from an event", () ->
		event = 'test:is:happening'
		handler = () ->
		@event.subscribeEvent event, handler
		len = _.size @event._events
		(expect len).toBe 1
		@event.unsubscribeEvent event, handler
		len = _.size @event._events
		(expect len).toBe 0

	it "then it is cleand up internally when there is no more callbacks hooked up on the event", () ->
		event = 'test:is:happening'
		handler = () ->
		(expect @event._events[event]).toBeUndefined()
		@event.subscribeEvent event, handler
		(expect @event._events[event]).not.toBeUndefined()
		@event.unsubscribeEvent event, handler
		(expect @event._events[event]).toBeUndefined()

describe "The publisher/subscribe implementation", () ->

	beforeEach () ->
		@propertyChanged = (newValue) ->

		@event = new Event
		@event._events = {}

		spyOn @, 'propertyChanged'

		@event.subscribeEvent 'change:property', @propertyChanged
		@event.publishEvent 'change:property', 'new prop'

	it "runs the callbacks hooked up on an event, when the event is fired", () ->
		(expect @propertyChanged).toHaveBeenCalled()

	it "should call the callbacks with the provided value from the publishEvent call", () ->
		(expect @propertyChanged).toHaveBeenCalledWith 'new prop'

	it "should handle multiple callbacks on the same event", () ->
		(expect @propertyChanged).toHaveBeenCalled()
		(expect @propertyChanged).toHaveBeenCalledWith('new prop')
		
		@anotherPropertyChanged = (newValue) ->
		spyOn @, 'anotherPropertyChanged'

		@event.subscribeEvent 'change:property', @anotherPropertyChanged
		@event.publishEvent 'change:property', 'another property changed'

		# expects the @propertyChanged to be called twice.
		(expect @propertyChanged.calls.length).toBe 2
		
		# the new callback to be called.
		(expect @anotherPropertyChanged).toHaveBeenCalled()
		(expect @anotherPropertyChanged).toHaveBeenCalledWith 'another property changed'
		(expect @propertyChanged).toHaveBeenCalledWith 'another property changed'

	it "should not call callbacks on events that new have been fired", () ->
		(expect @propertyChanged).toHaveBeenCalled()

		@anotherPropertyChanged = (newValue) ->
		spyOn @, 'anotherPropertyChanged'
		@event.subscribeEvent 'change:something', @anotherPropertyChanged
		@event.publishEvent 'change:somethingElse', 'changed something else'

		(expect @anotherPropertyChanged).not.toHaveBeenCalled()