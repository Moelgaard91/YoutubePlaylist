_ = require 'underscore'
jasmine = require 'jasmine-node'
{Event} = require '../src/background/event'
{Video} = require '../src/background/video'
{Playlist} = require '../src/background/playlist'

describe "Playlist", () ->

	beforeEach () ->
		@playlist = new Playlist
		@tab =
			id: 634
			title: "Foo Fighters - The Pretender - YouTube"
			url: "http://www.youtube.com/watch?v=SBjQ9tuuTJQ"

	describe "getNextId()", () ->

		it "should return a uniqueId", () ->
			(expect @playlist.getNextId()).not.toEqual @playlist.getNextId()

		it "should prefix video id when no argument is passed", () ->
			index = @playlist.getNextId().indexOf 'video'
			(expect index).toEqual 0

		it "should prefix the id with the first argument", () ->
			prefix = "musicvideo"
			id = @playlist.getNextId prefix
			index = id.indexOf prefix
			(expect index).toEqual 0

	describe "addVideo()", () ->

		it "should return no error and a video object on the addVideo callback", () ->
			@handler = (err, video) ->
			spyOn @, 'handler'

			@playlist.addVideo @tab, @handler
			(expect @handler).toHaveBeenCalledWith null, jasmine.any Video

		it "should return an error in callback when passing empty tab to addVideo", () ->
			@handler = (err, video) ->
			spyOn @, 'handler'

			@playlist.addVideo null, @handler
			(expect @handler).toHaveBeenCalledWith jasmine.any Object

		it "should update exiting tab, when adding a video based on tabId that already exists", () ->
			@playlist.addVideo @tab
			video = @playlist.list[@playlist.priority[0]]

			(expect video.title).toEqual @tab.title
			(expect video.videoUrl).toEqual @tab.url

			newTabInfo =
				id: 634
				title: "Foo Fighters - These Days - YouTube"
				url: "http://www.youtube.com/watch?v=5OWgxqoGedE"

			@playlist.addVideo newTabInfo

			(expect video.title).toEqual newTabInfo.title
			(expect video.videoUrl).toEqual newTabInfo.url

		it "should pulish the event add:video, and passing the newly created video", () ->
			@handler = (video) ->
			spyOn @, 'handler'

			@playlist.subscribeEvent 'add:video', @handler
			@playlist.addVideo @tab

			(expect @handler).toHaveBeenCalledWith jasmine.any Video

	describe "createVideo()", () ->

		it "should create video objects from tab hash", () ->
			createdVideo = @playlist.createVideo @tab
			(expect createdVideo).toBeDefined()
			video = new Video
				id:       createdVideo.id
				title:    @tab.title
				tab:      @tab
				videoUrl: @tab.url
				pending:  false
				playing:  false

			(expect createdVideo).toEqual video

		it "should throw an error when passing nothing", () ->
			(expect @playlist.createVideo).toThrow()

		it "should throw an error when passing invalid tab", () ->
			wrapper = () =>
				@playlist.createVideo title: "title", url: "http://www.youtube.com/watch?v=5f4C2dF"
			(expect wrapper).toThrow()

	describe "updateVideo()", () ->

		it "should update title and url of an existing video", () ->
			video = @playlist.createVideo @tab
			@playlist.updateVideo video, { id: @tab.id, title: "updated title - YouTube", url: "http://www.youtube.com/watch?v=rf4faDF43" }
			(expect video.title).toEqual "updated title - YouTube"
			(expect video.videoUrl).toEqual "http://www.youtube.com/watch?v=rf4faDF43"
			(expect video.tab.title).toEqual "updated title - YouTube"
			(expect video.tab.url).toEqual "http://www.youtube.com/watch?v=rf4faDF43"

	describe "CHANGE DESCRIPTION", () ->

		it "should keep the priority list and internal reference list in sync", () ->
			video = @playlist.createVideo @tab
			(expect @playlist.length).toEqual 0
			(expect @playlist.priority.length).toEqual 0
			(expect _.size(@playlist.list)).toEqual 0

			@playlist.pushToList video

			(expect @playlist.length).toEqual 1
			(expect @playlist.priority.length).toEqual 1
			(expect _.size(@playlist.list)).toEqual 1

			@playlist.listRemove video

			(expect @playlist.length).toEqual 0
			(expect @playlist.priority.length).toEqual 0
			(expect _.size(@playlist.list)).toEqual 0

		it "should keep the length property in sync with the internal lists", () ->
			(expect @playlist.length).toEqual 0

			v = null
			@playlist.addVideo @tab, (err, video) =>
				v = video
				(expect video).toBe @playlist.list[video.id]
			
			(expect @playlist.length).toEqual 1

			@playlist.removeVideo v, (err, video) =>
			 	(expect @playlist.length).toEqual 0
