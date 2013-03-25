fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'
mkdirp = require 'mkdirp'
_ = require 'underscore'
jasmine = require 'jasmine-node'

input = 'src'
output = 'build'

copyFile = (srcFile, destFile, cont) ->
	src = fs.createReadStream srcFile
	dest = fs.createWriteStream destFile

	src.pipe dest
	dest.on 'close', () ->
		cont?()

fs.find = (dir, ext, done) ->
	ext = [ext] if _.isString ext
	# checking if ext is present
	done = ext if _.isFunction ext
	results = []
	fs.readdir dir, (err, list) ->
		return done err if err
		i = 0
		(next = () ->
			file = list[i++]
			return done null, results unless file?
			file = path.join dir, file
			fs.stat file, (err, stat) ->
				if stat and stat.isDirectory()
					if _.isArray ext
						fs.find file, ext, (err, res) ->
							results = results.concat res
							return next()
					else
						fs.find file, (err, res) ->
							results = results.concat res
							return next()
				else
					if _.isArray ext # check if extension is defined
						fileExt = path.extname file
						results.push file if _.contains ext, fileExt
					else
						results.push file
					return next()
		)()

compileCoffee = (cont) ->
	console.log "Compiling coffee"
	exec "coffee -c -b -o #{output} #{input}", (err, stdout, stderr) ->
		console.error "Error trown: ", err if err?
		console.error "StdErr: ", stderr if stderr
		console.log "StdOut: ", stdout if stdout
		cont?()

task 'build', 'Builds the project', (options) ->
	console.log "Building project"
	compileCoffee () ->
		ext = [".js", ".css", ".html", ".png", ".gif", ".json"]
		console.log "Copying files: ", ext
		fs.find input, ext, (err, files) ->
			return console.error "fs.find error: ", err if err?
			i = 0
			(next = () ->
				file = files[i++]
				return console.log "Done" unless file?
				file = file.substring input.length+1
				dir = path.dirname path.join output, file
				mkdirp dir, () ->
					copyFile (path.join input, file), (path.join output, file), () ->
						return next()
			)()

task 'test', 'Run the test suite', (options) ->
	exec 'node ./node_modules/jasmine-node/lib/jasmine-node/cli.js --coffee --color --verbose tests', (err, stdout, stderr) ->
		console.log stdout