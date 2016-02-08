{CompositeDisposable} = require 'atom'

FileUtils = require './services/file-utils'
SelectProjectListView = require './views/select-project-list-view'
SelectStoryStartListView = require './views/select-story-start-list-view'
SelectStoryFinishListView = require './views/select-story-finish-list-view'
StatusBarView = require './views/status-bar-view'

NO_PROJECT = 'Atom Tracker requires an active Atom project'

module.exports = AtomTracker =

  config: require './atom-tracker-config'

  projectData: null
  state: null
  statusBarTile: null
  subscriptions: null

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
    atom.config.onDidChange 'atom-tracker.showStatusBar',
      ({newValue, oldValue}) =>
        @srefreshStatusBar()
    atom.config.onDidChange 'atom-tracker.colorizeStatusBar',
      ({newValue, oldValue}) =>
        @refreshStatusBar()
    atom.config.onDidChange 'atom-tracker.velocityStatusBar',
      ({newValue, oldValue}) =>
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
    if atom.project.getPaths().length > 0
      new SelectStoryStartListView(
        @projectData.project,
        @state.atomTrackerViewState
      ).reveal()
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  finishCurrentStory: ->
    if atom.project.getPaths().length > 0
      new SelectStoryFinishListView(
        @projectData.project,
        @state.atomTrackerViewState
      ).reveal()
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  createProjectConfig: ->
    if atom.project.getPaths().length > 0
      new SelectProjectListView(@state.atomTrackerViewState).reveal =>
        @readProjectConfig()
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

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
