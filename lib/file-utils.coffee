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
      if error
        failure error
      else
        success results

  writeCsonFile: (path, content, errMessage) ->
    CSON.writeFile @rootFilepath(path), content, (error) ->
      if error
        atom.notifications.addError errMessage or 'Failed to write file.',
          {detail: error.stack}
