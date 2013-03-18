# retrieve the background script of the extension.
bkg = chrome.extension.getBackgroundPage()

# the playlist object
playlist = bkg.playlist

# find the the playlist ul DOM element.
DOMPlaylist = document.getElementById 'playlist'

###
# Sets the control button's state of a playlist item.
# @param integer tabId
# @param boolean state
# @return void
###
setControlButtonState = (tabId, state) ->
	return unless (icon = document.getElementById "control-icon-#{tabId}")?
	if state then icon['className'] = 'icon-pause' else icon['className'] = 'icon-play'

###
# Sets the playing state of the li element
# @param integer tabId
# @param boolean state
# @return void
###
setItemState = (tabId, state) ->
	return unless (li = document.getElementById "item-#{tabId}")?
	if state then li['className'] = "active" else li['className'] = ""


###
# Create a control button.
# @param Video video
# @return HTMLButtonElement
###
createControls = (video) ->
	btn = document.createElement 'button'
	btn['className'] = 'btn btn-mini pull-right'
	btn['id'] = "control-btn-#{video.tabId}"
	# remember to parseInt when you retrieve the tabId from the data attribute
	# because the result will be a string, and it cannot be used
	# when dealing with chrome extension API, beacause the types are checked.
	btn.setAttribute 'data-tabId', video.tabId
	
	i = document.createElement 'icon'
	i['id'] = "control-icon-#{video.tabId}"
	i.setAttribute 'data-tabId', video.tabId
	if video.playing then	i['className'] = 'icon-pause' else i['className'] = 'icon-play'
	
	# listens to when the a video is playing.
	# to change the icon of the control button.
	video.subscribeEvent 'change:playing', (state) ->
		# set the new state of the control button.
		setControlButtonState @tabId, state
		setItemState @tabId, state
	
	# listens to when the control button is clicked,
	# to either start or stop the video.
	btn.addEventListener 'click', (e) ->
		e.stopPropagation()
		tabId = parseInt btn.getAttribute 'data-tabId'
		i = document.getElementById "control-icon-#{tabId}"
		if i['className'] is "icon-play"
			playlist.playVideo tabId
			isPlaying = yes
		else
			playlist.stopVideo tabId
			isPlaying = no

		# set the current state of the control button.
		setControlButtonState tabId, isPlaying
		return false

	btn.appendChild i
	return btn

###
# Create a playlist item.
# @param integer tabId
# @param Video video
# @return HTMLLiElement
###
createPlaylistItem = (tabId, video) ->
	a  = document.createElement 'a'
	li = document.createElement 'li'
	
	a.setAttribute 'data-tabId', tabId
	a['href'] = '#'
	
	if tabId isnt -1
		li['id'] = "item-#{tabId}"
		li['className'] = "active" if video.playing

		a['innerHTML']  = video.getFormattedTitle()
		a.appendChild createControls video
		a.addEventListener 'click', (e) ->
			tabId = parseInt a.getAttribute 'data-tabId'
			chrome.tabs.update tabId, selected: true
	else
		a['innerHTML'] = video.title
		a['className'] = "empty"
	
	li.appendChild a
	return li

###
# Initializing sortable list.
# @return void
###
initSortable = () ->
	$('#playlist').sortable
		axis: 'y'
		containment: "parent"
		forceHelperSize: yes
		forcePlaceholderSize: yes
		cancel: ".active, button, icon"
		items: "> li"
		opacity: .6
		distance: 5
		placeholder: "placeholder"
		start: (event, ui) ->
			# add the necessary HTML and classes to the placeholder
			# in order to render the list correctly when moving elements around.
			$("#playlist > .placeholder").addClass('active').html ui.item.html()
		update: (event, ui) ->
			# get a list of tab id, in the order
			# they are in the DOM right now.
			sortedItems = for a in $(@).find("> li > a")
				parseInt a.getAttribute 'data-tabId'
			
			# get the tab id of the moved item.
			tabId = parseInt ui.item.find('>a')[0].getAttribute 'data-tabId'
			
			# get the new index of the item we just moved.
			newIndex = sortedItems.indexOf tabId
			if newIndex is 0 and playlist.isPlaying()
				# you cannot move an item above a playing item.
				# which always will be at the top of the list.
				return $(@).sortable 'cancel'

			# if the tabId wasn't to be found,
			# then something's wrong.
			if newIndex is -1
				# re-render the playlist if a move goes wrong
				# because the damage is unrecoverable.
				renderPlaylist()
			else
				playlist.moveVideo tabId, newIndex, (err) ->
					# same story down here.
					renderPlaylist() if err?

###
# Render the playlist.
# @return void
###
renderPlaylist = () ->
	DOMPlaylist.innerHTML = ""
	if playlist.getPriority().length is 0
		DOMPlaylist.appendChild createPlaylistItem -1, title: "The playlist is empty."
	else
		for id in playlist.getPriority()
			video = playlist.getList()[id]
			DOMPlaylist.appendChild createPlaylistItem id, video
		initSortable()

# listens to when the a video is added to the playlist.
playlist.subscribeEvent 'add:video', (tabId, videoObject) ->
	renderPlaylist()

# listens to when a video is removed to the playlist.
playlist.subscribeEvent 'remove:video', (tabId) ->
	renderPlaylist()

# listens to when a video is moved around in the playlist.
playlist.subscribeEvent 'move:video', (priorityList) ->
	renderPlaylist()

# waits to the DOM is loaded.
document.addEventListener 'DOMContentLoaded', () ->
	# render the playlist when the DOM is loaded.
	renderPlaylist()
