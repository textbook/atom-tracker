{SelectListView} = require 'atom-space-pen-views'


FileUtils = require '../services/file-utils'
TrackerUtils = require '../services/tracker-utils'

module.exports = class NextStoryView extends SelectListView
  callback: null
  panel: null
  project: null

  MAX_LEN = 75

  initialize: (project) ->
    super
    @project = project
    @addClass('overlay from-top tracker-story-list')
    @setLoading 'Fetching story list...'
    TrackerUtils.getUnstartedStories project, @handleStories, (=> @panel?.hide())

  handleStories: (stories) ->
    filtered = stories.filter @filterItems
    if filtered.length
      @setItems filtered
    else
      @panel?.hide()
      errMsg = "No unstarted stories in the \"#{@project.name}\" backlog"
      atom.notifications.addWarning errMsg

  filterItems: (story) ->
    # Remove stories the user can't actually start
    if story.story_type is 'release'
      return false
    else if story.story_type is 'feature' and story.estimate is undefined
      return false
    return true

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
    # Trunate long story names
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

  getFilterKey: -> 'project_name'

  confirmed: (item) ->
    @panel?.hide()
    TrackerUtils.startStory item

  cancelled: -> @panel.hide()
