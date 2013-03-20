# Changelog for YouTube Playlist

### Version 1.0.4 - 2013-03-20

* Made the initial work for large playlist support, it works now, if the user treat it, as intended, but having some problems, with controlling when a tab is removed, then another tab should open.
* Added support for restoring "pending" videos, but there is a little problem controlling the desktop notifications for now.

### Version 1.0.3 - 2013-03-19

* Fixed: The last item is removed from the list when the playlist is finished, but keeps the tab open, so the user has the oppotunity to add more videos.
* Rewritten the playlist, to not use tabId as map look up, but our own object counter instead, this is a preparation for implementing tab rotation, in order to support more than 20 items on the playlist, due to flash is crashing when have to many open instances.
* Added the video url on video object; preparation for tab restore in tab rotation.
* Made some of the work internally in the playlist class more abstract.

### Version 1.0.2 - 2013-03-19

* Rewrote the browserAction script to use jQuery all over the place for DOM traversal and manipulation, this made the code a bit cleaner, and more consistent.

### Version 1.0.1 - 2013-03-19

* Minor bug fixes.
* Added icons - still working on the 128x128 version, it comes in later release
* Plays video added to the playlist right away, if it is the only item in the list.

### Version 1.0.0 - 2013-03-18

* Updated the playlist pop interface with new colors
* Added artwork
* Added desktop notifications when adding to playlist, plays a video and updates an existing video.
* Added sortable UI, enables you to change the priority of the playlist items via drag and drop.

### Version 0.9.0 - 2013-03-17

* Added autodetect of youtube video tabs and add them to the playlist
* Made videos pause when opens them, so they don't start automatically
* Added interface where you can browse the playlist
* Added play / pause functionality in the playlist popup
* Added autodetect of closing youtube video tabs, and remove them from the playlist