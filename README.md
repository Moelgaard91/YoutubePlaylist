# YoutubePlaylist Chrome Extension #

Licence: BSD

This extension for Google Chrome helps you manage playback of YouTube videos, creating playlist based on the tabs you have open, this way the videos is preloaded and thus makes the shifting between videos almost gapless.

## Getting started

First of all it is necessary to have NodeJS installed, after that you have to install the coffee-script compiler globally via the NodeJS's package manager NPM:

		npm install -g coffee-script

When you have gloned the project, navigate to the root of the project in a shell, and run:

		npm install

Now all the needed software is downloaded and intalled, the only thing missing is building the project, this is done by running:

		cake build

## Installing the extension

1. Open Google Chrome and navigate to `chrome://extensions`
2. Enable `Developer Mode`, if haven't done so already.
3. Now two extra buttons becomes visible, hit the Load unpacked extension, and navigate to the build directory inide the project and click `Open`

## Credits

In this extension we have used some great icons made by:

Paul Robert Lloyd - [http://paulrobertlloyd.com](http://paulrobertlloyd.com)

Under the [Attribution-Share Alike 2.0 UK: England & Wales Licence](http://creativecommons.org/licenses/by-sa/2.0/uk)