# Roadmap for YouTube Playlist

### Version 1.2.0

* Handle more than 20 tabs, without flash crashes, and causes the extension to fail.
* Change the concept of tabId as unique identifiers in the playlist, because it will
not work, when we implement the "more than 20 tabs" feature.
* Handle when moving playlist items from 20+ into the "open tabs" playlist,
and of course the other way around.
* Make a distinguish way of showing which video has an open tab and which are pending.
* Implement tab rotation, when a video is done and removed, and there is 20+ items in the playlist,
so the next item opens a tab - we may have to rethink the way out event handling works internally.
* Removing element from the playlist via the popup.

### Version 1.4.0

* Make a settings interface, where you can change behaviours of the extension.
* Make desktop notificatoin customizable.
* Make how many tabs can be open at once customizable, which affects the tab rotation.
* Make a setting where you can disable the extension by right clicking on the popup button.
