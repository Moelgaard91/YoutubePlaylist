document.addEventListener 'DOMContentLoaded', () ->
	bkg = chrome.extension.getBackgroundPage()
	playlist = bkg.playlist

	viewModel =
		list: ko.observable playlist.getList()
		priority: ko.observableArray playlist.getPriority()
		videos: ko.computed () ->
			res = []
			debugger
			for tabId in @priority()
				res.push @list()[tabId]
			return res
		, viewModel
		togglePlay: () ->
			debugger

	ko.applyBindings viewModel