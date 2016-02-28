{SelectListView} = require 'atom-space-pen-views'

FileUtils = require '../services/file-utils'
TrackerUtils = require '../services/tracker-utils'

# FIXME Views aren't being destroyed when no longer required [#114634305]

module.exports = class SelectStoryListView extends SelectListView
  callback: null
  panel: null
  project: null

  MAX_LEN: 75

  initialize: (project) ->
    super
    @project = project
    @addClass 'overlay from-top tracker-story-list atom-tracker'
    @setLoading 'Fetching story list...'

  filterItems: (item) ->
    return true

  handleStories: (stories) ->
    filtered = stories.filter @filterItems
    if filtered.length
      @setItems filtered
    else if @project
      @setError "No matching stories in the #{@project.name} backlog"
    else
      @panel?.hide()

  setPlaceholder: (text) ->
    this.find('.editor.mini')[0].getModel().setPlaceholderText text

  reveal: (successCallback) ->
    @callback = successCallback
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  configureItem: (item) ->
    # Defaults
    config =
      iconClass: 'icon-star'
      pointSpan: ''
      name: item.name
    # Set icon based on story type
    if item.story_type is 'bug'
      config.iconClass = 'icon-bug'
    else if item.story_type is 'chore'
      config.iconClass = 'icon-gear'
    # Display estimated points if appropriate
    if item.story_type is 'feature' and atom.config.get 'atom-tracker.showFeatureEstimate'
      config.pointSpan = "  <span class=\"badge badge-small badge-info\">" +
        "#{item.estimate}</span>"
    # Truncate long story names
    if config.name.length > @MAX_LEN
      name = config.name.slice(0, @MAX_LEN - 3)
      if config.name.slice(@MAX_LEN - 3, @MAX_LEN - 2) isnt ' '
        name = name.slice(0, name.lastIndexOf ' ')
      config.name = name + '...'
    return config

  viewForItem: (item) ->
    config = @configureItem item
    # Build element string
    "<li class=\"tracker-story\">" +
    "  <span class=\"icon #{config.iconClass}\"></span>" +
    "  <span>#{config.name}</span>" +
    config.pointSpan +
    "</li>"

  getFilterKey: -> 'name'

  cancelled: -> @panel.hide()
