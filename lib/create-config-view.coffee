{SelectListView} = require 'atom-space-pen-views'


FileUtils = require './file-utils'
TrackerUtils = require './tracker-utils'

module.exports = class CreateConfigView extends SelectListView
  panel: null

  initialize: ->
    super
    @addClass('overlay from-top')
    @setLoading 'Fetching project data'
    TrackerUtils.getProjects ((projects) => @setItems projects),
      (=> @panel.hide() if @panel)

  reveal: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) -> "<li>#{item.project_name}</li>"

  getFilterKey: -> 'project_name'

  confirmed: (item) ->
    TrackerUtils.getProjectDetails item, (data) =>
      FileUtils.writeCsonFile null, {currentProject: data}, 'Failed to write configuration file.',
        @panel.hide()

  cancelled: -> @panel.hide()
