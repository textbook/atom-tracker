CSON = require 'season'
fs = require 'fs'
jschardet = require 'jschardet'
path = require 'path'

module.exports =

  eraseComment: (story) ->
    location = story.description.match(/^comment location: `(\S+) (\d+)`$/mi)
    if not location
      return
    filePath = location[1]
    line = parseInt(location[2])
    absPath = path.join atom.project.getPaths()[0], filePath
    fs.readFile absPath, (err, data) ->
      if data
        {encoding} = jschardet.detect data
        content = data.toString encoding
        if content
          pattern = ///^.+\[\##{story.id}\].*\n///m
          fs.writeFile absPath, content.replace(pattern, ''), encoding

  configFile: ->
    atom.config.get 'atom-tracker.projectConfigFile'

  rootFilepath: (filename) ->
    if not filename
      filename = @configFile()
    path.join(atom.project.getPaths()[0], filename)

  relativePath: (filepath) ->
    paths = atom.project.getPaths()
    if paths.length > 0
      return path.relative paths[0], filepath
    return filepath

  readCsonFile: (path, success, failure) ->
    CSON.readFile path, (error, results) ->
      if error
        failure? error
      else
        success? results

  writeCsonFile: (path, content, errMessage, success) ->
    CSON.writeFile @rootFilepath(path), content, (error) ->
      if error
        atom.notifications.addError errMessage or 'Failed to write file.',
          {detail: error.stack}
      else if success
        success()
