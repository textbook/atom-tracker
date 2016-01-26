{SelectListView} = require 'atom-space-pen-views'

CSON = require 'season'
https = require 'https'
path = require 'path'

FileUtils = require './file-utils.coffee'

module.exports = class CreateConfigView extends SelectListView
  panel: null

  initialize: ->
    super
    @addClass('overlay from-top')
    @setLoading 'Fetching project data'
    @getProjects ((projects) => @setItems projects),
      (=> @panel.hide() if @panel)

  getProjects: (success, failure) ->
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'
      path: '/services/v5/me'
    req = https.get options, (res) ->
      if res.statusCode is 200
        res.setEncoding 'utf8'
        data = []
        res.on 'data', (chunk) -> data.push(chunk)
        res.on 'end', ->
          success JSON.parse(data.join '').projects or []
      else
        if res.statusCode is 403
          atom.notifications.addWarning 'Not authenticated, please double-' +
            'check your Tracker API Token in the package settings.',
            {icon: 'lock'}
        else
          atom.notifications.addError 'Failed to fetch project data.'
        failure()

  reveal: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) -> "<li>#{item.project_name}</li>"

  getFilterKey: -> 'project_name'

  confirmed: (item) ->
    # Write a configuration file to the project root directory
    projectConfig =
      currentProject: item
    CSON.writeFile FileUtils.rootFilepath(), projectConfig, (error) ->
      if error
        atom.notifications.addError 'Failed to write configuration file.',
          {detail: error.stack}
    @panel.hide()

  cancelled: -> @panel.hide()
