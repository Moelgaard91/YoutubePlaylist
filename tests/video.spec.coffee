_ = require 'underscore'
{Event} = require '../src/background/event'
{Video} = require '../src/background/video'

describe "The video property bag", () ->

	beforeEach () ->
		@video = new Video

	it "should be able to use the constructor to set every property in the prototype", () ->
		video = new Video
			id: "video1"
			videoUrl: "http://www.youtube.com/watch?v=SBjQ9tuuTJQ"
			playing: no
			tab:
				id: 432
				url: "http://www.youtube.com/watch?v=SBjQ9tuuTJQ"
				windowId: 1
			title: "Foo Figthers - The Pretender - YouTube"
			pending: no

		(expect video.id).toEqual "video1"
		(expect video.videoUrl).toEqual "http://www.youtube.com/watch?v=SBjQ9tuuTJQ"
		(expect video.playing).toBeFalsy()
		(expect video.tab.id).toEqual 432
		(expect video.tab.url).toBe "http://www.youtube.com/watch?v=SBjQ9tuuTJQ"
		(expect video.tab.windowId).toEqual 1
		(expect video.title).toEqual "Foo Figthers - The Pretender - YouTube"
		(expect video.pending).toBeFalsy()

	it "should be able to set all properties via the setters, except the id", () ->
		@video.setPlaying yes
		@video.setTitle "Foo Figthers - These Days - YouTube"
		@video.setVideoUrl "http://www.youtube.com/watch?v=5OWgxqoGedE"
		@video.setTab
			id: 371
			url: "http://www.youtube.com/watch?v=5OWgxqoGedE"
			windowId: 1
		@video.setTitle "Foo Figthers - These Days - YouTube"
		@video.setPending yes

		(expect @video.id).toBeNull()
		(expect @video.videoUrl).toEqual "http://www.youtube.com/watch?v=5OWgxqoGedE"
		(expect @video.playing).toBeTruthy()
		(expect @video.tab.id).toEqual 371
		(expect @video.tab.url).toEqual "http://www.youtube.com/watch?v=5OWgxqoGedE"
		(expect @video.tab.windowId).toEqual 1
		(expect @video.title).toEqual "Foo Figthers - These Days - YouTube"
		(expect @video.pending).toBeTruthy()

	it "should remove the - YouTube suffix at the end of a video title", () ->
		@video.setTitle "Linkin Park - Numb - YouTube"
		(expect @video.getFormattedTitle()).toEqual "Linkin Park - Numb"

	it "should return the title as it is, if there is no - YouTube suffix", () ->
		@video.setTitle "Weird guy hits himself"
		(expect @video.getFormattedTitle()).toEqual "Weird guy hits himself"

describe "The video mixin event publishing when properties changes using the setters", () ->

	beforeEach () ->
		@video = new Video

	it "should fire a callback when subscribed to events", () ->
		@playingChanged = (playing) ->
		@titleChanged = (title) ->
		@videoUrlChanged = (videoUrl) ->
		@pendingChanged = (pending) ->
		@tabChanged = (tab) ->

		spyOn @, 'playingChanged'
		spyOn @, 'titleChanged'
		spyOn @, 'videoUrlChanged'
		spyOn @, 'pendingChanged'
		spyOn @, 'tabChanged'

		@video.subscribeEvent 'change:playing', @playingChanged
		@video.subscribeEvent 'change:title', @titleChanged
		@video.subscribeEvent 'change:videoUrl', @videoUrlChanged
		@video.subscribeEvent 'change:pending', @pendingChanged
		@video.subscribeEvent 'change:tab', @tabChanged

		@video.setPlaying yes
		@video.setTitle 'Foo Figthers - The Pretender - YouTube'
		@video.setVideoUrl 'http://www.youtube.com/watch?v=SBjQ9tuuTJQ'
		@video.setPending yes
		tab = id: 542
		@video.setTab tab

		expect(@playingChanged).toHaveBeenCalled()
		expect(@playingChanged).toHaveBeenCalledWith yes
		expect(@titleChanged).toHaveBeenCalled()
		expect(@titleChanged).toHaveBeenCalledWith 'Foo Figthers - The Pretender - YouTube'
		expect(@videoUrlChanged).toHaveBeenCalled()
		expect(@videoUrlChanged).toHaveBeenCalledWith 'http://www.youtube.com/watch?v=SBjQ9tuuTJQ'
		expect(@pendingChanged).toHaveBeenCalled()
		expect(@pendingChanged).toHaveBeenCalledWith yes
		expect(@tabChanged).toHaveBeenCalled()
		expect(@tabChanged).toHaveBeenCalledWith tab

	it "should return true in hasTab if there is a tab attached", () ->
		expect(@video.hasTab()).toBeFalsy()
		@video.setTab id: 542
		expect(@video.hasTab()).toBeTruthy()

	it "should return false in hasTab if there is no tab attached", () ->
		@video.setTab id: 456
		expect(@video.hasTab()).toBeTruthy()
		@video.setTab null
		expect(@video.hasTab()).toBeFalsy()

	it "should trigger change event when changing tab id", () ->
		@video.setTab id: 542
		@tabChanged = (tab) ->
		spyOn @, 'tabChanged'

		@video.subscribeEvent 'change:tab', @tabChanged

		@video.setTab id: 432

		expect(@tabChanged).toHaveBeenCalled()
		expect(@tabChanged).toHaveBeenCalledWith id: 432

	it "should trigger change event when changing set a tab to null", () ->
		@video.setTab id: 674
		@tabChanged = (tab) ->
		spyOn @, 'tabChanged'

		@video.subscribeEvent 'change:tab', @tabChanged

		@video.setTab null

		expect(@tabChanged).toHaveBeenCalled()
		expect(@tabChanged).toHaveBeenCalledWith null