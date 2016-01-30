{CompositeDisposable} = require 'atom'

CreateConfigView = require './create-config-view'
FileUtils = require './file-utils'
StatusBarView = require './status-bar-view'

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
    projectConfigFile:
      default: '.tracker.cson'
      description: 'This file will store the project-specific configuration, ' +
        'e.g. project Tracker ID, in your root project directory.'
      order: 5
      title: 'Project Configuration File Name'
      type: 'string'

  activate: (state) ->
    @state = state
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:create-config': => @createProjectConfig()
    atom.config.onDidChange 'atom-tracker.showStatusBar', ({newValue, oldValue}) =>
      @statusBarTile?.getItem().display newValue and @projectData
    atom.config.onDidChange 'atom-tracker.colorizeStatusBar', ({newValue, oldValue}) =>
      if @projectData
        @statusBarTile?.getItem().updateContent @projectData
    atom.config.onDidChange 'atom-tracker.velocityStatusBar', ({newValue, oldValue}) =>
      if @projectData
        @statusBarTile?.getItem().updateContent @projectData
    @readProjectConfig()

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile item: new StatusBarView, priority: 5
    if @projectData
      @statusBarTile.getItem().display atom.config.get 'atom-tracker.showStatusBar'
      @statusBarTile.getItem().updateContent @projectData
    else
      @statusBarTile.getItem().display false

  createProjectConfig: ->
    new CreateConfigView(@state.atomTrackerViewState).reveal =>
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
