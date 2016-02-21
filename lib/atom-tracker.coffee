{CompositeDisposable} = require 'atom'

path = require 'path'

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
      buffer = editor.getBuffer()
      lineNo = editor.getCursorBufferPosition().row
      line = buffer.getLines()[lineNo]
      grammar = editor.getGrammar()
      if grammar
        @processTodoLine line, grammar,
          "Comment location: `#{path.basename buffer.file.path} #{lineNo + 1}`"
      else
        atom.notifications.addError 'Grammar definition required to create ' +
          'story from comment'
    else
      atom.notifications.addError 'Active editor required to create story ' +
        'from comment'

  getTodoComment: (tokens) ->
    comment = false
    todo = false
    for token in tokens
      if comment and todo
        return token.value.trim()
      else if token.scopes.length > 2 and token.scopes[2].startsWith 'punctuation.definition.comment'
        comment = true
      else if token.scopes.length > 2 and token.scopes[2] is 'storage.type.class.todo'
        todo = true
    return null

  processTodoLine: (line, grammar, description) ->
    {tokens} = grammar.tokenizeLine line.trim()
    comment = @getTodoComment tokens
    if comment
      if comment.match /\[#\d+\]/
        atom.notifications.addError 'Story already created', {icon: 'gear'}
      else
        TrackerUtils.createStory @projectData.project.id,
        {name: comment, story_type: 'chore', description: description},
        (data) =>
          atom.notifications.addSuccess "Created story \"#{data.name}\" " +
            "[##{data.id}]", {icon: 'gear'}
          @insertNewId data
    else
      atom.notifications.addWarning "Not a TODO comment line"

  insertNewId: (data) ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      view = atom.views.getView(editor)
      atom.commands.dispatch view, 'editor:toggle-line-comments'
      editor.moveToEndOfLine()
      editor.insertText " [##{data.id}]"
      atom.commands.dispatch view, 'editor:toggle-line-comments'
    else
      atom.notifications.addError 'Active editor required to insert ID'

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
