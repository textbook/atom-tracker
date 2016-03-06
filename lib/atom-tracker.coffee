{CompositeDisposable} = require 'atom'

FileUtils = require './services/file-utils'
TrackerUtils = require './services/tracker-utils'

StoryView = require './views/story-view'
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
      'atom-tracker:create-new-story': => @createNewStory()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:finish-story': => @finishCurrentStory()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:next-story': => @selectNextStory()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:next-story-auto': => @selectNextStoryAuto()

    # Monitor configuration changes
    atom.config.onDidChange 'atom-tracker.showStatusBar',
      ({newValue, oldValue}) =>
        @refreshStatusBar()
    atom.config.onDidChange 'atom-tracker.colorizeStatusBar',
      ({newValue, oldValue}) =>
        @refreshStatusBar()
    atom.config.onDidChange 'atom-tracker.velocityStatusBar',
      ({newValue, oldValue}) =>
        @refreshStatusBar()
    # Initialise with current project data
    @readProjectConfig()

  refreshStatusBar: ->
    if @projectData and @statusBarTile
      @statusBarTile.getItem().display atom.config.get 'atom-tracker.showStatusBar'
      @statusBarTile.getItem().updateContent @projectData

  createNewStory: ->
    if @projectData
      editor = atom.workspace.getActiveTextEditor()
      if editor
        buffer = editor.getBuffer()
        grammar = editor.getGrammar()
        lineNo = editor.getCursorBufferPosition().row
        line = buffer?.getLines()[lineNo]
        if line
          @processTodoLine line, editor, "Comment location: " +
            "`#{FileUtils.relativePath buffer.file.path} #{lineNo + 1}`"
      else
        new StoryView @projectData

  getTodoComment: (tokens, commentType) ->
    comment = false
    match = false
    for token in tokens
      if comment and match
        return token.value.trim()
      else if @commentToken token
        comment = true
      else if @commentTypeToken token, commentType
        match = true
    return null

  commentToken: (token) ->
    if token and token.scopes and token.scopes.length > 2
      return token.scopes[2].startsWith 'punctuation.definition.comment'
    return false

  commentTypeToken: (token, commentType) ->
    if token and token.scopes and token.scopes.length > 2
      return token.scopes[2] is commentType
    return false

  processTodoLine: (line, editor, description) ->
    grammar =  editor.getGrammar()
    {tokens} = grammar.tokenizeLine line.trim()
    lineTypes = [
      {storyType: 'chore', commentType: 'storage.type.class.todo', icon: 'gear'}
      {storyType: 'bug', commentType: 'storage.type.class.fixme', icon: 'bug'}
    ]
    for {storyType, commentType, icon} in lineTypes
      comment = @getTodoComment tokens, commentType
      if comment
        if comment.match /\[#\d+\]/
          atom.notifications.addError 'Story already created', {icon: icon}
          return
        else
          story =
            story_type: storyType
            name: comment
            description: description
          new StoryView @projectData, story, (data) => @insertNewId data
          return
    new StoryView @projectData

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
    if @validateProjectData()
      new SelectStoryStartListView(
        @projectData.project,
        @state.atomTrackerViewState
      ).reveal()

  validateProjectData: ->
    if atom.project.getPaths().length > 0
      if @projectData
        return true
      else
        atom.notifications.addWarning NO_TRACKER, {icon: 'graph'}
    else
      atom.notifications.addWarning NO_PROJECT, {icon: 'graph'}
    return false

  selectNextStoryAuto: ->
    if @validateProjectData()
      TrackerUtils.getUnstartedStories @projectData.project,
        @autostartStory

  autostartStory: (data) ->
    if data.length is 0
      atom.notifications.addWarning 'No stories currently available to start',
        {icon: 'graph'}
    else
      TrackerUtils.startStory data[0]

  finishCurrentStory: ->
    if @validateProjectData()
      new SelectStoryFinishListView(
        @projectData.project,
        @state.atomTrackerViewState
      ).reveal()

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
