# retrieve the playlist from the background script.
bkg = chrome.extension.getBackgroundPage()
playlist = bkg.playlist
_ = bkg._

# whether the DOM is loaded or not.
DOMIsLoaded = false

# find the the playlist ul DOM element.
$DOMPlaylist = null

# map from id to the corresponding jQuery li element.
listItems = {}
# map from id to the corresponding jQuery a element.
links = {}
# map from id to the corresponding jQuery button element.
buttons = {}
# map from id to the corresponding jQuery icon element.
icons = {}

###
# Sets the control button's state of a playlist item.
# @param string id
# @param boolean state
# @return void
###
setControlButtonState = (id, state) ->
	if state
		icons[id]?[0]['className'] = 'icon-pause'
	else
		icons[id]?[0]['className'] = 'icon-play'

###
# Sets the playing state of the li element.
# @param string id
# @param boolean state
# @return void
###
setItemState = (id, state) ->
	if state
		listItems[id]?.addClass 'active'
	else
		listItems[id]?.removeClass 'active'

###
# Create a play/pause icon for a video.
# @param Video video
# @return jQuery icon
###
createPlayPauseIcon = (video) ->
	# save the video element on the icon
	$i = $('<icon />')
		.data('video', video)
	# update icons map
	icons[video.id] = $i
	# setting the current state of the button.
	$i.addClass if video.playing then 'icon-pause' else 'icon-play'
	return $i

###
# Create a play/pause button for a video.
# @param Video video
# @return jQuery button
###
createPlayPauseButton = (video) ->
	# create button and save the video object on it.
	$btn = $('<button />')
		.addClass('btn btn-mini pull-right')
		.data('video', video)
	# update buttons map
	buttons[video.id] = $btn

	# listen to pending changes.
	video.subscribeEvent 'change:pending', (pending) ->
		buttons[@id]?.prop('disabled', pending)

	# determine whether or not the contols should be active.
	# disable pending videos.
	$btn.prop('disabled', true) if video.pending

	$i = createPlayPauseIcon video
	# append icon to button.
	$btn.append $i
	return $btn

###
# Create a control button.
# @param Video video
# @return jQuery button
###
createControls = (video) ->
	$btn = createPlayPauseButton video
	
	# listens to when the a video is playing.
	# to change the icon of the control button.
	# NB! important the this parameter, is bound to the video object,
	#     on which the event occured.
	video.subscribeEvent 'change:playing', (state) ->
		# set the new state of the control button.
		setControlButtonState @id, state
		setItemState @id, state
	
	# listens to when the control button is clicked,
	# to either start or stop the video.
	$btn.on 'click', (e) ->
		e.stopPropagation()
		# get the video object from the button.
		video = $(@).data 'video'

		if (state = video.playing)
			playlist.stopVideo video, (err, video) ->
				console.error "pause: Couln't stop video", err, video if err?
		else
			playlist.playVideo video, (err, video) ->
				console.error "play: Couldn't start video", err, video if err?

		# set the current state of the control button.
		setControlButtonState video.id, (not state)
		return false

	return $btn

###
# Create link "title" for a video
# @param Video video
# @return jQuery a
###
createLink = (video) ->
	# creating the link and saves the video object on the link.
	$a = $('<a />')
		.attr('href', '#')
		.data('video', video)
	# update links map.
	links[video.id] = $a

	# -1 is the ugly special case of the "The playlist is empty" element.
	if video.id isnt -1
		$a.addClass 'video'
		# listen to title change event.
		video.subscribeEvent 'change:title', (title) ->
			links[@id]?.contents()[0].textContent = @getFormattedTitle()

		# hooking click handler up on the link, to set the active tab.
		$a.on 'click', (e) ->
			e.stopPropagation()
			e.preventDefault()
			video = $(@).data('video')
			return false if video.pending
			playlist.activateTab video, (err, video, tab) ->
				console.error "selectTab: Couldn't activate tab", err, video, tab if err?
			return false

	return $a

###
# Create a remove button for a video.
# @param Video video
# @return jQuery a
###
createRemoveLink = (video) ->
	# creating element.
	$a = $('<a />')
		.addClass('close')
		.html('&times;')
		.data('video', video)
	
	# hooking event handlers up.
	$a.on 'click', (e) ->
		e.stopPropagation()
		e.preventDefault()
		video = $(@).data 'video'
		
		# remove the video only internally because,
		# it is either the last video in the list,
		# and we would like to keep the tab openend then.
		if video.pending or playlist.length is 1
			if playlist.length is 1
				playlist.sendMsg video, 'stop', (err) ->
					console.error "remove: Couldn't send msg", err if err?
			playlist.removeVideo video, (err, video) ->
				console.error "remove: Couldn't remove video", err, video if err?
			return false

		# simply just remove the tab, and the events handle the rest.
		# if the tab is not the last item in the list,
		# and it is not pending, ergo it has a tab open.
		chrome.tabs.remove video.tab.id
		return false
	return $a

###
# Create a playlist item.
# @param integer id
# @param Video video
# @return jQuery li
###
createPlaylistItem = (video) ->
	# create link
	$a = createLink video
	
	# creating the list item and add the video object on the list.
	$li = $('<li />').data('video', video)
	# update listItems map.
	listItems[video.id] = $li

	# create remove button.	
	$remove = createRemoveLink video

	# append a tag on list item.
	$li.append $a

	# if the video object isn't a special case, hence -1 id
	if video.id isnt -1
		$li.prepend $remove
		# setting listItem active if the video is playing.
		$li.addClass 'active' if video.playing
		# setting listItem pending if the video is pending.
		$li.addClass 'disabled' if video.pending		
		# insert the title.
		$a.text video.getFormattedTitle()
		# append the controls to the link.
		$a.append createControls video

		video.subscribeEvent 'change:pending', (pending) ->
			listItems[@id]?.toggleClass('disabled', pending)
		
	else
		# this is a special case, used for empty playlist element.
		$a.text video.title
		$a.addClass('empty')
	
	return $li

###
# Returns the order the elements are in the DOM
# @return array<integer>
###
getSortedList = () ->
	for a in $DOMPlaylist.find('>li')
		$(a).data('video').id

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
		cancel: "button, icon, a.close"
		items: ">li:not(.active)"
		opacity: .6
		distance: 5
		placeholder: "placeholder"
		start: (event, ui) ->
			# add the necessary HTML and classes to the placeholder
			# in order to render the list correctly when moving elements around.
			$("#playlist > .placeholder").html ui.item.html()
		update: (event, ui) ->
			# get a list of tab id, in the order
			# they are in the DOM right now.
			sortedItems = getSortedList()
			
			# get the tab id of the moved item.
			video = ui.item.data 'video'
			
			# get the new index of the item we just moved.
			newIndex = sortedItems.indexOf video.id
			if newIndex is 0 and playlist.isPlaying()
				# you cannot move an item above a playing item.
				# which always will be at the top of the list.
				return $(@).sortable 'cancel'

			# if the id wasn't to be found,
			# then something's wrong.
			if newIndex is -1
				# re-render the playlist if a move goes wrong
				# because the damage is unrecoverable.
				renderPlaylist()
			else
				playlist.moveVideo video, newIndex, (err) ->
					console.error "move: Couldn't move video", err if err?
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
# Create empty playlist item.
# @return jQuery li
###
createEmptyPlaylistItem = () ->
	createPlaylistItem id: -1, title: "The playlist is empty."

###
# Render the playlist.
# @return void
###
renderPlaylist = (clear = true) ->
	# clearing the DOM an maps
	clearDOMAndMaps() if clear

	# creating empty playlist element.
	if playlist.getPriority().length is 0
		$DOMPlaylist.append createEmptyPlaylistItem()
	else
		for id in playlist.getPriority()
			video = playlist.getList()[id]
			$DOMPlaylist.append createPlaylistItem video
		# initialize sortable
	initSortable()

###
# Removes all references to elements connected to a certain id.
# @param integer id
# @return void
###
listRemove = (id) ->
	delete icons[id]
	delete buttons[id]
	delete links[id]
	delete listItems[id]

###
# Insert a new element into the DOM, or move an existing element,
# with a nice a little animation.
# @param jQuery $li
# @param integer index
# @param [ boolean isInDOM = true ]
# @return void
###
arrangeItemInDOM = ($li, index, isInDOM = true) ->
	if index is 0
		if $DOMPlaylist.find(".empty").length > 0
			$DOMPlaylist.empty().append $li
			return $li.slideDown()
		if isInDOM
			return $li.slideUp () ->
				$(@).insertBefore($DOMPlaylist.find "li:eq(0)").slideDown()
		return $li.insertBefore($DOMPlaylist.find "li:eq(0)").slideDown()
	
	if isInDOM
		return $li.slideUp () ->
			$(@).insertAfter($DOMPlaylist.find "li:eq(#{index-1})").slideDown()
	return $li.insertAfter($DOMPlaylist.find "li:eq(#{index-1})").slideDown()

# listens to when the a video is added to the playlist.
playlist.subscribeEvent 'add:video', (video) ->
	return unless DOMIsLoaded
	index = playlist.getPriority().indexOf video.id
	return renderPlaylist() if index is -1
	$li = createPlaylistItem video
	arrangeItemInDOM $li.hide(), index, false

# listens to when a video is removed to the playlist.
playlist.subscribeEvent 'remove:video', (video) ->
	return unless DOMIsLoaded
	if ($li = listItems[video.id])?
		$li.slideUp () ->
			$(@).remove()
		listRemove video.id
	if playlist.getPriority().length is 0
		$DOMPlaylist.append createEmptyPlaylistItem()

# listens to when a video is moved around in the playlist.
playlist.subscribeEvent 'move:video', (video, index, priorityList) ->
	return unless DOMIsLoaded
	return if _.isEqual priorityList, getSortedList()
	return renderPlaylist() unless ($li = listItems[video.id])?
	arrangeItemInDOM $li, index

# waits to the DOM is loaded.
document.addEventListener 'DOMContentLoaded', () ->
	$DOMPlaylist = $('#playlist')
	DOMIsLoaded = true
	# render the playlist when the DOM is loaded.
	renderPlaylist()
