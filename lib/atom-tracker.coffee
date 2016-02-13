{CompositeDisposable} = require 'atom'

FileUtils = require './services/file-utils'
TrackerUtils = require './services/tracker-utils'

SelectProjectListView = require './views/select-project-list-view'
SelectStoryStartListView = require './views/select-story-start-list-view'
SelectStoryFinishListView = require './views/select-story-finish-list-view'
StatusBarView = require './views/status-bar-view'

NO_PROJECT = 'Atom Tracker requires an active Atom project'
NO_TRACKER = 'Atom Tracker is not configured for this project'

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
      'atom-tracker:next-story': => @selectNextStory()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:create-todo-story': => @createTodoStory()
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

  createTodoStory: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      line = editor.getBuffer().getLines()[editor.getCursorBufferPosition().row]
      @processTodoLine line, editor
    else
      msg = 'Active editor required to create story from comment'
      atom.notifications.addError msg

  processTodoLine: (line, editor) ->
    match = line.match /TODO:?\s*(.+)/
    if match
      name = match[1].trim()
      if name.match /\[#\d{9}\]/
        atom.notifications.addError 'Story already created', {icon: 'gear'}
      else
        editor.moveToEndOfLine()
        TrackerUtils.createStory @projectData.project.id,
        {name: name, story_type: 'chore'}, (data) ->
          msg = "Created story \"#{data.name}\" [##{data.id}]"
          atom.notifications.addSuccess msg, {icon: 'gear'}
          editor.insertText " [##{data.id}]"
    else
      atom.notifications.addWarning "No TODO in '#{line}'"

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile item: new StatusBarView, priority: 5
    if @projectData
      @statusBarTile.getItem().display atom.config.get 'atom-tracker.showStatusBar'
      @statusBarTile.getItem().updateContent @projectData
    else
      @statusBarTile.getItem().display false

  selectNextStory: ->
    if atom.project.getPaths().length > 0
      if @projectData
        new SelectStoryStartListView(
          @projectData.project,
          @state.atomTrackerViewState
        ).reveal()
      else
        atom.notifications.addWarning NO_TRACKER, {icon: 'graph'}
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  finishCurrentStory: ->
    if atom.project.getPaths().length > 0
      if @projectData
        new SelectStoryFinishListView(
          @projectData.project,
          @state.atomTrackerViewState
        ).reveal()
      else
        atom.notifications.addWarning NO_TRACKER, {icon: 'graph'}
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  createProjectConfig: ->
    if atom.project.getPaths().length > 0
      new SelectProjectListView(@state.atomTrackerViewState).reveal =>
        @readProjectConfig()
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  readProjectConfig: ->
    if atom.project.getPaths().length > 0
      FileUtils.readCsonFile FileUtils.rootFilepath(), (results) =>
        @projectData = results
        tile = @statusBarTile?.getItem()
        tile.updateContent results
        tile.display atom.config.get 'atom-tracker.showStatusBar'
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}

  deactivate: ->
    @subscriptions.dispose()
    @atomTrackerView?.destroy()
    @atomTrackerView = null
    @statusBarTile?.destroy()
    @statusBarTile = null

  serialize: ->
    if @atomTrackerView
      atomTrackerViewState: @atomTrackerView.serialize()
