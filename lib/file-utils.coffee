CSON = require 'season'
path = require 'path'

module.exports =

  configFile: ->
    atom.config.get 'atom-tracker.projectConfigFile'

  rootFilepath: (filename) ->
    if not filename
      filename = @configFile()
    path.join(atom.project.getPaths()[0], filename)
