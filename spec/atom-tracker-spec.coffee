AtomTracker = require '../lib/atom-tracker'

TrackerUtils = require '../lib//services/tracker-utils'
StoryView = require '../lib/views/story-view'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomTracker", ->

  [workspaceElement, activationPromise] = []

  beforeEach ->
    spyOn(AtomTracker, 'readProjectConfig')
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-tracker')

  it 'should define the expected configuration', ->
    for config in ['trackerToken', 'showStatusBar', 'colorizeStatusBar',
        'velocityStatusBar', 'showFeatureEstimate', 'projectConfigFile']
      expect(AtomTracker.config[config]).not.toBe(undefined)

  it 'should read the project configuration', ->
    expect(AtomTracker.readProjectConfig).toHaveBeenCalled()

  describe 'when the atom-tracker:create-config event is triggered', ->

    it 'should call createProjectConfig', ->
      spyOn(AtomTracker, 'createProjectConfig')
      atom.commands.dispatch workspaceElement, 'atom-tracker:create-config'
      expect(AtomTracker.createProjectConfig).toHaveBeenCalled()

  describe 'when the atom-tracker:next-story event is triggered', ->

    it 'should call selectNextStory', ->
      spyOn(AtomTracker, 'selectNextStory')
      atom.commands.dispatch workspaceElement, 'atom-tracker:next-story'
      expect(AtomTracker.selectNextStory).toHaveBeenCalled()

  describe 'when the atom-tracker:next-story-auto event is triggered', ->

    it 'should call selectNextStoryAuto', ->
      spyOn(AtomTracker, 'selectNextStoryAuto')
      atom.commands.dispatch workspaceElement, 'atom-tracker:next-story-auto'
      expect(AtomTracker.selectNextStoryAuto).toHaveBeenCalled()

  describe 'when the atom-tracker:finish-story event is triggered', ->

    it 'should call finishCurrentStory', ->
      spyOn(AtomTracker, 'finishCurrentStory')
      atom.commands.dispatch workspaceElement, 'atom-tracker:finish-story'
      expect(AtomTracker.finishCurrentStory).toHaveBeenCalled()

  describe 'when the atom-tracker:create-new-story event is triggered', ->

    it 'should call createNewStory', ->
      spyOn(AtomTracker, 'createNewStory')
      atom.commands.dispatch workspaceElement, 'atom-tracker:create-new-story'
      expect(AtomTracker.createNewStory).toHaveBeenCalled()

  parameterized = (testCase) ->
    describe "when the #{testCase} config is changed", ->
      config = null

      beforeEach ->
        @config = "atom-tracker.#{testCase}"

      it 'refreshes the status bar', ->
        atom.config.set @config, true
        spyOn(AtomTracker, 'refreshStatusBar')
        atom.config.set @config, false
        expect(AtomTracker.refreshStatusBar).toHaveBeenCalled()

  parameterized 'colorizeStatusBar'
  parameterized 'showStatusBar'
  parameterized 'velocityStatusBar'

  describe 'refreshStatusBar method', ->
    data = null
    item = null

    beforeEach ->
      # coffeelint: disable=no_empty_functions
      @data =
        foo: 'bar'
      @item =
        display: ->
        updateContent: null
      AtomTracker.statusBarTile =
        getItem: => @item
        destroy: ->
      # coffeelint: enable=no_empty_functions


    it 'should update the content if projectData is available', ->
      spyOn(@item, 'updateContent')
      AtomTracker.projectData = @data
      AtomTracker.refreshStatusBar()
      expect(@item.updateContent).toHaveBeenCalledWith(@data)

    it 'should do nothing if projectData is not available', ->
      spyOn(@item, 'updateContent')
      AtomTracker.projectData = {}
      AtomTracker.refreshStatusBar()
      expect(@item.updateContent).not.toHaveBeenCalledWith(@data)

  describe 'processTodoLine method', ->
    editor = null
    grammar = null
    line = null
    location = null

    beforeEach ->
      AtomTracker.projectData = {project: {id: 1234567}}
      @grammar =
        tokenizeLine: jasmine.createSpy('tokenizeLine').andReturn {tokens: []}
      @editor =
        getGrammar: jasmine.createSpy('getGrammar').andReturn @grammar
      @line = 'TODO: take over the world'
      @location = 'Where the comment was'
      spyOn atom.notifications, 'addSuccess'
      spyOn(TrackerUtils, 'createStory').andCallFake (projectId, story, func) ->
        expect(projectId).toEqual(1234567)
        expect(story).toEqual
          name: 'take over the world',
          story_type: 'chore'
          description: 'Where the comment was'
        func({name: 'take over the world', id: 123456789})
      spyOn(AtomTracker, 'insertNewId')

    it 'should tokenize the line', ->
      spyOn AtomTracker, 'getTodoComment'
      AtomTracker.processTodoLine '  foo  ', @editor, @location
      expect(@grammar.tokenizeLine).toHaveBeenCalledWith 'foo'

    it 'should get the comment from the tokens', ->
      spyOn AtomTracker, 'getTodoComment'
      AtomTracker.processTodoLine 'foo', @editor
      for commentType in ['storage.type.class.todo', 'storage.type.class.fixme']
        expect(AtomTracker.getTodoComment).toHaveBeenCalledWith [], commentType

    it 'should not allow creation of stories if comment already has ID', ->
      spyOn(AtomTracker, 'getTodoComment').andReturn 'foo [#123456789]'
      spyOn(atom.notifications, 'addError')
      AtomTracker.processTodoLine '', @editor
      expect(atom.notifications.addError).toHaveBeenCalledWith(
        'Story already created', {icon: 'gear'}
      )

  describe 'insertNewId method', ->

    it 'should warn if there is no editor', ->
      spyOn(atom.workspace, 'getActiveTextEditor').andReturn null
      spyOn(atom.notifications, 'addError')
      AtomTracker.insertNewId()
      expect(atom.notifications.addError).toHaveBeenCalledWith 'Active editor' +
        ' required to insert ID'

    it 'should add the ID to the end of the line if present', ->
      mockEditor =
        moveToEndOfLine: jasmine.createSpy 'moveToEndOfLine'
        insertText: jasmine.createSpy 'insertText'
      fakeView = {fake: 'view'}
      spyOn(atom.workspace, 'getActiveTextEditor').andReturn mockEditor
      spyOn(atom.views, 'getView').andReturn fakeView
      spyOn(atom.commands, 'dispatch')
      AtomTracker.insertNewId {id: 123456789}
      expect(mockEditor.moveToEndOfLine).toHaveBeenCalled()
      expect(mockEditor.insertText).toHaveBeenCalledWith ' [#123456789]'
      expect(atom.views.getView).toHaveBeenCalledWith mockEditor
      expect(atom.commands.dispatch).toHaveBeenCalledWith fakeView,
        'editor:toggle-line-comments'
      expect(atom.commands.dispatch.callCount).toEqual(2)

  describe 'getTodoComment method', ->
    commentScope = null
    todoScope = null

    beforeEach ->
      @commentScope = [null, null, 'punctuation.definition.comment.language']
      @todoScope = [null, null, 'storage.type.class.todo']

    it 'should return the first token after both comment and TODO', ->
      tokens = [{scopes: @todoScope}, {scopes: @commentScope}, {value: 'foo'}]
      expect(AtomTracker.getTodoComment tokens, 'storage.type.class.todo').toEqual 'foo'

    it 'should return null if no TODO', ->
      tokens = [{scopes: @commentScope}]
      expect(AtomTracker.getTodoComment tokens, 'storage.type.class.todo').toBe null

    it 'should return null if no comment', ->
      tokens = [{scopes: @todoScope}]
      expect(AtomTracker.getTodoComment tokens, 'storage.type.class.todo').toBe null

  describe 'commentToken method', ->
    it 'should return true for tokens matching the expected pattern', ->
      token =
        scopes: [null, null, 'punctuation.definition.comment.language']
      expect(AtomTracker.commentToken token).toBeTruthy()

  describe 'commentTypeToken method', ->
    it 'should return true for tokens matching the expected pattern', ->
      token =
        scopes: [null, null, 'foo.bar.baz']
      expect(AtomTracker.commentTypeToken token, 'foo.bar.baz').toBeTruthy()

  describe 'validateProjectData method', ->

    it 'should show a warning and return false if there is no active project path', ->
      spyOn(atom.project, 'getPaths').andReturn {length: 0}
      spyOn(atom.notifications, 'addWarning')
      result = AtomTracker.validateProjectData()
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'Atom Tracker requires an active Atom project', {icon: 'graph'}
      )
      expect(result).toBeFalsy()

    it 'should show a warning and return false if there is no project data', ->
      spyOn(atom.project, 'getPaths').andReturn {length: 1}
      AtomTracker.projectData = null
      spyOn(atom.notifications, 'addWarning')
      result = AtomTracker.validateProjectData()
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'Atom Tracker is not configured for this project', {icon: 'graph'}
      )
      expect(result).toBeFalsy()

    it 'should return true otherwise', ->
      spyOn(atom.project, 'getPaths').andReturn {length: 1}
      AtomTracker.projectData = {}
      result = AtomTracker.validateProjectData()
      expect(result).toBeTruthy()

  describe 'selectNextStoryAuto method', ->

    beforeEach ->
      spyOn(AtomTracker, 'validateProjectData').andReturn true

    it 'should call validated the project data', ->
      spyOn(TrackerUtils, 'getUnstartedStories')
      AtomTracker.selectNextStoryAuto()
      expect(AtomTracker.validateProjectData).toHaveBeenCalled()

    it 'should get unstarted stories', ->
      spyOn(TrackerUtils, 'getUnstartedStories')
      AtomTracker.projectData = {project: {}}
      AtomTracker.selectNextStoryAuto()
      expect(TrackerUtils.getUnstartedStories).toHaveBeenCalledWith {},
        AtomTracker.autostartStory

  describe 'autostartStory method', ->

    it 'should show a warning if no stories are available', ->
      spyOn(atom.notifications, 'addWarning')
      AtomTracker.autostartStory []
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'No stories currently available to start', {icon: 'graph'}
      )

    it 'should start the first story if some are available', ->
      spyOn(TrackerUtils, 'startStory')
      AtomTracker.autostartStory [{foo: 'bar'}, {bar: 'baz'}]
      expect(TrackerUtils.startStory).toHaveBeenCalledWith {foo: 'bar'}
