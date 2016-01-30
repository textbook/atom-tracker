{SelectListView} = require 'atom-space-pen-views'


FileUtils = require './file-utils'
TrackerUtils = require './tracker-utils'

module.exports = class CreateConfigView extends SelectListView
  callback: null
  panel: null

  initialize: ->
    super
    @addClass('overlay from-top tracker-project-list')
    @setLoading 'Fetching project data'
    TrackerUtils.getProjects ((projects) => @setItems projects),
      (=> @panel.hide() if @panel)

  reveal: (successCallback) ->
    @callback = successCallback
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) ->
    "<li class=\"tracker-project\">" +
    "  <span class=\"icon icon-graph\"></span>" +
    "  <span>#{item.project_name}</span>" +
    "  <span class=\"text-subtle project-role\">#{item.role}</span>" +
    "</li>"

  getFilterKey: -> 'project_name'

  confirmed: (item) ->
    @panel.hide()
    TrackerUtils.getProjectDetails item, (data) =>
      FileUtils.writeCsonFile null, {project: data, membership_summary: item},
        'Failed to write configuration file.', @callback

  cancelled: -> @panel.hide()
