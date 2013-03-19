# retrieve the playlist from the background script.
playlist = chrome.extension.getBackgroundPage().playlist

# find the the playlist ul DOM element.
$DOMPlaylist = $('#playlist')

# map from tabId to the corresponding jQuery li element.
listItems = {}
# map from tabId to the corresponding jQuery a element.
links = {}
# map from tabId to the corresponding jQuery button element.
buttons = {}
# map from tabId to the corresponding jQuery icon element.
icons = {}

###
# Sets the control button's state of a playlist item.
# @param integer tabId
# @param boolean state
# @return void
###
setControlButtonState = (tabId, state) ->
	if state
		icons[tabId][0]['className'] = 'icon-pause'
	else
		icons[tabId][0]['className'] = 'icon-play'

###
# Sets the playing state of the li element.
# @param integer
# @param boolean state
# @return void
###
setItemState = (tabId, state) ->
	if state
		listItems[tabId][0]['className'] = 'active'
	else
		listItems[tabId][0]['className'] = ''


###
# Create a control button.
# @param Video video
# @return jQuery
###
createControls = (video) ->
	# create button and save the video object on it.
	$btn = $('<button />')
		.addClass('btn btn-mini pull-right')
		.data('video', video)
	# update buttons map
	buttons[video.tabId] = $btn

	# save the video element on the icon
	$i = $('<icon />')
		.data('video', video)
	# update icons map
	icons[video.tabId] = $i
	# setting the current state of the button.
	$i.addClass if video.playing then 'icon-pause' else 'icon-play'
	# append icon to button.
	$btn.append $i
	
	# listens to when the a video is playing.
	# to change the icon of the control button.
	# NB! important the this parameter, is bound to the video object,
	#     on which the event occured.
	video.subscribeEvent 'change:playing', (state) ->
		# set the new state of the control button.
		setControlButtonState @tabId, state
		setItemState @tabId, state
	
	# listens to when the control button is clicked,
	# to either start or stop the video.
	$btn.on 'click', (e) ->
		e.stopPropagation()
		# get the video object from the button.
		video = $(@).data 'video'

		if (state = video.playing)
			playlist.stopVideo video.tabId
		else
			playlist.playVideo video.tabId

		# set the current state of the control button.
		setControlButtonState video.tabId, (not state)
		return false

	return $btn

###
# Create a playlist item.
# @param integer tabId
# @param Video video
# @return jQuery
###
createPlaylistItem = (video) ->
	# creating the link and saves the video object on the link.
	$a = $('<a />')
		.attr('href', '#')
		.data('video', video)
	# update links map.
	links[video.tabId] = $a

	# creating the list item and add the video object on the list.
	$li = $('<li />').data('video', video)
	# update listItems map.
	listItems[video.tabId] = $li
	
	# append a tag on list item.
	$li.append $a

	# if the video object isn't a special case, hence -1 tabId
	if video.tabId isnt -1
		# setting listItem active if the video is playing.
		$li.addClass 'active' if video.playing
		# insert the title.
		$a.text video.getFormattedTitle()
		# append the controls to the link.
		$a.append createControls video
		# hooking click handler up on the link, to set the active tab.
		$a.on 'click', (e) ->
			video = $(@).data('video')
			chrome.tabs.update video.tabId, selected: true
	else
		# this is a special case, used for empty playlist element.
		$a.text video.title
		$a.addClass('empty')
	
	return $li

###
# Initializing sortable list.
# @return void
###
initSortable = () ->
	$DOMPlaylist.sortable
		axis: 'y'
		forceHelperSize: yes
		forcePlaceholderSize: yes
		containment: "window"
		cancel: "button, icon"
		items: ">li:not(.active)"
		opacity: .6
		distance: 5
		placeholder: "placeholder"
		tolerange: "pointer"
		start: (event, ui) ->
			# add the necessary HTML and classes to the placeholder
			# in order to render the list correctly when moving elements around.
			$("#playlist > .placeholder").html ui.item.html()
		update: (event, ui) ->
			# get a list of tab id, in the order
			# they are in the DOM right now.
			sortedItems = for a in $(@).find('>li>a')
				$(a).data('video').tabId
			
			# get the tab id of the moved item.
			tabId = ui.item.data('video').tabId
			
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
# Clear objects and DOM
# @return void
###
clearDOMAndMaps = () ->
	listItems = {}
	links = {}
	buttons = {}
	icons = {}
	$DOMPlaylist.empty()

###
# Render the playlist.
# @return void
###
renderPlaylist = (clear = true) ->
	# clearing the DOM an maps
	clearDOMAndMaps() if clear

	# creating empty playlist element.
	if playlist.getPriority().length is 0
		$DOMPlaylist.append createPlaylistItem tabId: -1, title: "The playlist is empty."
	else
		for id in playlist.getPriority()
			video = playlist.getList()[id]
			$DOMPlaylist.append createPlaylistItem video
		# initialize sortable
		initSortable()

# listens to when the a video is added to the playlist.
playlist.subscribeEvent 'add:video', (tabId, videoObject) ->
	# TODO: handle this better, then just re-render every time something happens.
	renderPlaylist()

# listens to when a video is removed to the playlist.
playlist.subscribeEvent 'remove:video', (tabId) ->
	# TODO: handle this better, then just re-render every time something happens.
	renderPlaylist()

# listens to when a video is moved around in the playlist.
playlist.subscribeEvent 'move:video', (priorityList) ->
	# TODO: handle this better, then just re-render every time something happens.
	renderPlaylist()

# waits to the DOM is loaded.
document.addEventListener 'DOMContentLoaded', () ->
	# render the playlist when the DOM is loaded.
	renderPlaylist()
