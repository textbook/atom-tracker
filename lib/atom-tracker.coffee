{CompositeDisposable} = require 'atom'

FileUtils = require './services/file-utils'
SelectStoryStartListView = require './views/select-story-start-list-view'
SelectStoryFinishListView = require './views/select-story-finish-list-view'
SelectProjectListView = require './views/select-project-list-view'
StatusBarView = require './views/status-bar-view'

module.exports = AtomTracker =
  projectData: null
  state: null
  statusBarTile: null
  subscriptions: null

  config:
    trackerToken:
      default: ''
      description: 'Your access token for the Tracker API. Find it online at ' +
        'https://www.pivotaltracker.com/profile#api.'
      order: 1
      title: 'Tracker API Token'
      type: 'string'
    showStatusBar:
      default: true
      description: 'Show Atom Tracker status in the status bar.'
      order: 2
      title: 'Show Status Bar'
      type: 'boolean'
    colorizeStatusBar:
      default: false
      description: 'Use the project color in the status bar.'
      order: 3
      title: 'Colorize Status Bar'
      type: 'boolean'
    velocityStatusBar:
      default: false
      description: 'Show the project\'s current velocity in the status bar.'
      order: 4
      title: 'Show Velocity in Status Bar'
      type: 'boolean'
    showFeatureEstimate:
      default: true
      description: 'Show features\' estimated points when selecting a story.'
      order: 5
      title: 'Show Estimates in Story Selector'
      type: 'boolean'
    projectConfigFile:
      default: '.tracker.cson'
      description: 'This file will store the project-specific configuration, ' +
        'e.g. project Tracker ID, in your root project directory.'
      order: 6
      title: 'Project Configuration File Name'
      type: 'string'

  activate: (state) ->
    @state = state
    # Set up Atom Tracker commands
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:create-config': => @createProjectConfig()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:next-story': => @selectNextStory()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:finish-story': => @finishCurrentStory()
    # Monitor configuration changes
    atom.config.onDidChange 'atom-tracker.showStatusBar', ({newValue, oldValue}) =>
      @srefreshStatusBar()
    atom.config.onDidChange 'atom-tracker.colorizeStatusBar', ({newValue, oldValue}) =>
      @refreshStatusBar()
    atom.config.onDidChange 'atom-tracker.velocityStatusBar', ({newValue, oldValue}) =>
      @refreshStatusBar()
    # Initialise with current project data
    @readProjectConfig()

  refreshStatusBar: ->
    if @projectData
      @statusBarTile?.getItem().updateContent @projectData

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile item: new StatusBarView, priority: 5
    if @projectData
      @statusBarTile.getItem().display atom.config.get 'atom-tracker.showStatusBar'
      @statusBarTile.getItem().updateContent @projectData
    else
      @statusBarTile.getItem().display false

  selectNextStory: ->
    new SelectStoryStartListView(
      @projectData.project,
      @state.atomTrackerViewState
    ).reveal()

  finishCurrentStory: ->
    new SelectStoryFinishListView(
      @projectData.project,
      @state.atomTrackerViewState
    ).reveal()

  createProjectConfig: ->
    new SelectProjectListView(@state.atomTrackerViewState).reveal =>
      @readProjectConfig()

  readProjectConfig: ->
    paths = atom.project.getPaths()
    if paths.length > 0
      FileUtils.readCsonFile FileUtils.rootFilepath(), (results) =>
        @projectData = results
        tile = @statusBarTile?.getItem()
        tile.updateContent results
        tile.display atom.config.get 'atom-tracker.showStatusBar'

  deactivate: ->
    @subscriptions.dispose()
    @atomTrackerView?.destroy()
    @atomTrackerView = null
    @statusBarTile?.destroy()
    @statusBarTile = null

  serialize: ->
    if @atomTrackerView
      atomTrackerViewState: @atomTrackerView.serialize()
