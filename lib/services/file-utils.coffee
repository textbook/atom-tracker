CSON = require 'season'
path = require 'path'

module.exports =

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
