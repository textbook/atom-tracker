CSON = require 'season'
path = require 'path'

module.exports =

  configFile: ->
    atom.config.get 'atom-tracker.projectConfigFile'

  rootFilepath: (filename) ->
    if not filename
      filename = @configFile()
    path.join(atom.project.getPaths()[0], filename)

  readCsonFile: (path, success, failure) ->
    CSON.readFile path, (error, results) ->
      if error and failure
        failure error
      else if success
        success results

  writeCsonFile: (path, content, errMessage, success) ->
    CSON.writeFile @rootFilepath(path), content, (error) ->
      if error
        atom.notifications.addError errMessage or 'Failed to write file.',
          {detail: error.stack}
      else if success
        success()