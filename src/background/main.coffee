STATE_UNSTARTED  = -1
STATE_ENDED      = 0
STATE_PLAYING    = 1
STATE_PAUSED     = 2
STATE_BUFFERING  = 3
STATE_VIDEO_CUED = 5

# constructs a playlist
playlist = new Playlist

###
# map holding the currently active desktop notifications
# this is mainly used, to prevent double triggering of notifications.
# @var object { eventString: Notification }
###
desktopNotifications = {}

###
# The state chenge handler.
# @param string state
# @param Video video
# @return void
###
onStateChange = (state, video) ->
	switch state
		when STATE_PLAYING
			playlist.setPlaying video, (err, video) ->
				console.error "onStateChange: Couldn't set video playing", err, video if err?
		when STATE_PAUSED
			playlist.setPaused video, (err, video) ->
				console.error "onStateChange: Couldn't set video paused", err, video if err?
		when STATE_ENDED
			playlist.playNext (err) ->
				console.error "onStateChange: Couldn't play next video", err if err?
		# when STATE_UNSTARTED
		# when STATE_BUFFERING
		# when STATE_VIDEO_CUED 

###
# Create desktop notification
# @param object options
# 	@option integer id
# 	@option string title
# 	@option string body
# 	@option [ integer timeout = 5000 ]
# 	@option [ boolean autoShow = true ]
# @return Notification
###
showDesktopNotification = (options) ->
	defaults =
		timeout: 5000
		autoShow: true

	# extending defaults with options.
	options = _.extend defaults, options
	# throw error if the required options isn't defined.
	return console.error "id, title and body has to be defined" if not options.id? or not options.title? or not options.body?
	
	# returns if the desktop notification is already showing.
	return if desktopNotifications[options.id]?

	# creating desktop notification object.
	notification = webkitNotifications.createNotification 'browserAction/img/logo_48.png', options.title, options.body
	
	# handling duplicates problem of desktop notification
	desktopNotifications[options.id] = notification
	notification.onclose = () ->
		delete desktopNotifications[options.id]

	# auto show/close.
	if options.autoShow
		notification.show()
		if options.timeout > 0
			setTimeout () ->
				notification.close()
			, options.timeout

	return notification

# listener that removes a video from the playlist, if it's tab is closed.
chrome.tabs.onRemoved.addListener (tabId) ->
	return unless (video = playlist.getVideoByTab tabId, (byId = yes))?
	# if the video is pending, it means that a video has been added,
	# but the playlist has reached max length, so the video tab has been removed.
	# and the video has been set in pending state, so the video should not be removed.
	unless video.pending
		playlist.removeVideo video, (err, video) ->
			console.error "onTabRemove: Couldn't remove video", err, video if err?

# initialize event listeners of the message channels
# between the content scripts, that is injected into the DOM.
# greeting is send from the content script,
# to let us know that the dom has been initialize,
# and we adds the video to the playlist, and sets its state to pasued,
# futhermore we listens to state changes of the video.
chrome.extension.onMessage.addListener (request, sender) ->
	return unless request?
	switch request.event
		when 'Greetings'
			playlist.addVideo sender.tab,  (err, video) ->
				return console.error "onGreetings: Couldn't add video", err, video if err?
				unless playlist.length is 1
					playlist.stopVideo video, (err, video) ->
						#console.error "onTabGreetings: Couldn't stop video", err, video if err?
		when 'stateChange'
			video = playlist.getVideoByTab sender.tab
			onStateChange request.state, video
		else console.error "unknown event: #{request.event}"

# catch if a tab that we know to contain a video,
# navigates away from youtube watch pages,
# and then remove it from the playlist.
chrome.webNavigation.onCommitted.addListener (details) ->
	return unless (video = playlist.getVideoByTab details.tabId, (byId = yes))?
	# for some reason every navigation commits a
	# navigation to about:blank before redirecting the actual requested site.
	return if details.url is 'about:blank'
	if details.url.indexOf("youtube.com/watch") is -1
		playlist.removeVideo video, (err, video) ->
			console.error "onCommittedNavigation: Couldn't remove video", err, video if err?

# creates desktop notification, when something important happens.
# and hook up click handlers to activate the tab where the video is.
playlist.subscribeEvent 'add:video', (video) ->
	notification = showDesktopNotification
		id: "add:video:#{video.tab.id}"
		title: "Video added to playlist"
		body: video.getFormattedTitle()
	notification?.onclick = () ->
		playlist.activateTab video, (err) ->
			console.error "addNotification: Couldn't activate tab", err if err?

playlist.subscribeEvent 'update:video', (video) ->
	notification = showDesktopNotification
		id: "update:video:#{video.tab.id}"
		title: "Video updated in playlist"
		body: video.getFormattedTitle()
	notification?.onclick = () ->
		playlist.activateTab video, (err) ->
			console.error "updateNotification: Couldn't activate tab", err if err?

playlist.subscribeEvent 'start:video', (video) ->
	notification = showDesktopNotification
		id: "start:video:#{video.tab.id}"
		title: "Video now playing"
		body: video.getFormattedTitle()
	notification?.onclick = () ->
		playlist.activateTab video, (err) ->
			console.error "stateNotification: Couldn't activateTab", err if err?
