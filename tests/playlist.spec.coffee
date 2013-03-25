_ = require 'underscore'
{Event} = require '../src/background/event'
{Video} = require '../src/background/video'
{Playlist} = require '../src/background/playlist'

describe "The backend playlist implementation", () ->
	it "should work", () ->
		