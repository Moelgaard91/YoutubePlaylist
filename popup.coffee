# function showList() {
#	var bkg = chrome.extension.getBackgroundPage();
#	//bkg.niels();
#	var list = bkg.getPlaylist();
#	var priority = bkg.getPriority();
#
#	console.log(list);
#	console.log(priority);	
#
#	var ul = document.createElement('ul');
#	console.log(ul);
#
#	for (var i=0 ; i < priority.length; i++)
#	{ 
#		var li = document.createElement('li');
#
#		var song = list[priority[i]];
#		console.log(song.title);
#
#		li.appendChild(document.createTextNode(song.title));
#		console.log(li);
#		ul.appendChild(li);
#		console.log(song);
#	}
#
#	document.body.appendChild(ul);
#	//console.log(bkg);
#}

#document.addEventListener 'DOMContentLoaded', showList
document.addEventListener 'DOMContentLoaded', () -> do showList

showList = () ->
	console.log 'here we go!'
	bkg = do chrome.extension.getBackgroundPage
	list = do bkg.getPlaylist
	priority = do bkg.getPriority

	console.log list
	console.log priority

	ul = document.createElement 'ul'
	console.log ul

	i = 0;

	while (i < priority.length)
		console.log 'iteration ' + i
		console.log priority[i]

		li = document.createElement 'li'

		song = list[priority[i]]
		console.log song.title

		#link = document.createElement 'a'
		a = document.createElement 'a'
		linkText = document.createTextNode song.title

		a.appendChild linkText
		a.href = ''
		a.title = 'another title' + priority[i]
		a.id = priority[i]
		a.target = "_blank"
		a.addEventListener 'onClick', ->
			console.log 'roger that'
			playSong priority[i]

		li.appendChild a

		#li.appendChild document.createTextNode song.title
		console.log li

		ul.appendChild li
		console.log song

		i++;

	document.body.appendChild ul

playSong = (priority) ->
	console.log 'Let me play that song for you..'
	console.log priority
	chrome.extension.getBackgroundPage.playSong priority

	return false

console.log 'niels'
console.log 'niels!'
