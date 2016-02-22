AtomTracker = require '../lib/atom-tracker'
TrackerUtils = require '../lib//services/tracker-utils'

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

  describe 'when the atom-tracker:create-todo-story event is triggered', ->

    it 'should call createTodoStory', ->
      spyOn(AtomTracker, 'createTodoStory')
      atom.commands.dispatch workspaceElement, 'atom-tracker:create-todo-story'
      expect(AtomTracker.createTodoStory).toHaveBeenCalled()

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
      @data =
        foo: 'bar'
      @item =
        display: null
        updateContent: null
      AtomTracker.statusBarTile =
        getItem: => @item
        # coffeelint: disable=no_empty_functions
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
      AtomTracker.processTodoLine '  foo  ', @grammar, @location
      expect(@grammar.tokenizeLine).toHaveBeenCalledWith 'foo'

    it 'should get the comment from the tokens', ->
      spyOn AtomTracker, 'getTodoComment'
      AtomTracker.processTodoLine 'foo', @grammar
      expect(AtomTracker.getTodoComment).toHaveBeenCalledWith []

    it 'should only trigger on lines containing "TODO"', ->
      spyOn AtomTracker, 'getTodoComment'
      spyOn(atom.notifications, 'addWarning')
      AtomTracker.processTodoLine 'foo', @grammar
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'Not a TODO comment line'
      )

    it 'should not allow creation of stories if comment already has ID', ->
      spyOn(AtomTracker, 'getTodoComment').andReturn 'foo [#123456789]'
      spyOn(atom.notifications, 'addError')
      AtomTracker.processTodoLine '', @grammar
      expect(atom.notifications.addError).toHaveBeenCalledWith(
        'Story already created', {icon: 'gear'}
      )

    it 'should call createStory and notify the user', ->
      spyOn(AtomTracker, 'getTodoComment').andReturn 'take over the world'
      AtomTracker.processTodoLine @line, @grammar, @location
      expect(TrackerUtils.createStory).toHaveBeenCalled()
      expect(atom.notifications.addSuccess).toHaveBeenCalledWith(
        'Created story "take over the world" [#123456789]', {icon: 'gear'}
      )

    it 'should update the active editor', ->
      spyOn(AtomTracker, 'getTodoComment').andReturn 'take over the world'
      AtomTracker.processTodoLine @line, @grammar, @location
      expect(AtomTracker.insertNewId).toHaveBeenCalledWith
        name: 'take over the world'
        id: 123456789

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

  describe 'createTodoStory method', ->
    mockEditor = null

    beforeEach ->
      @mockEditor =
        getBuffer:
          jasmine.createSpy('getBuffer').andReturn
            getLines: jasmine.createSpy('getLines').andReturn ['foo', 'bar']
            file:
              path: 'some/dir/test.coffee'
        getCursorBufferPosition:
          jasmine.createSpy('getCursorBufferPosition').andReturn {row: 1}
        getGrammar: jasmine.createSpy('getGrammar').andReturn {}
      spyOn(AtomTracker, 'processTodoLine')

    it 'should get the appropriate grammar', ->
      spyOn(atom.workspace, 'getActiveTextEditor').andReturn @mockEditor
      AtomTracker.createTodoStory()
      expect(@mockEditor.getGrammar).toHaveBeenCalled()

    it 'should show an error if no editor is active', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.workspace, 'getActiveTextEditor').andReturn(null)
      AtomTracker.createTodoStory()
      expect(atom.notifications.addError).toHaveBeenCalledWith(
        'Active editor required to create story from comment'
      )

    it 'should process the active line', ->
      spyOn(atom.workspace, 'getActiveTextEditor').andReturn @mockEditor
      AtomTracker.createTodoStory()
      expect(AtomTracker.processTodoLine).toHaveBeenCalledWith 'bar', {},
        'Comment location: `test.coffee 2`'

  describe 'getTodoComment method', ->
    commentScope = null
    todoScope = null

    beforeEach ->
      @commentScope = [null, null, 'punctuation.definition.comment.language']
      @todoScope = [null, null, 'storage.type.class.todo']

    it 'should return the first token after both comment and TODO', ->
      tokens = [{scopes: @todoScope}, {scopes: @commentScope}, {value: 'foo'}]
      expect(AtomTracker.getTodoComment tokens).toEqual 'foo'

    it 'should return null if no TODO', ->
      tokens = [{scopes: @commentScope}]
      expect(AtomTracker.getTodoComment tokens).toBe null

    it 'should return null if no comment', ->
      tokens = [{scopes: @todoScope}]
      expect(AtomTracker.getTodoComment tokens).toBe null

  # describe "when the atom-tracker:toggle event is triggered", ->
  #   it "hides and shows the modal panel", ->
  #     # Before the activation event the view is not on the DOM, and no panel
  #     # has been created
  #     expect(workspaceElement.querySelector('.atom-tracker')).not.toExist()
  #
  #     # This is an activation event, triggering it will cause the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'atom-tracker:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       expect(workspaceElement.querySelector('.atom-tracker')).toExist()
  #
  #       atomTrackerElement = workspaceElement.querySelector('.atom-tracker')
  #       expect(atomTrackerElement).toExist()
  #
  #       atomTrackerPanel = atom.workspace.panelForItem(atomTrackerElement)
  #       expect(atomTrackerPanel.isVisible()).toBe true
  #       atom.commands.dispatch workspaceElement, 'atom-tracker:toggle'
  #       expect(atomTrackerPanel.isVisible()).toBe false
  #
  #   it "hides and shows the view", ->
  #     # This test shows you an integration test testing at the view level.
  #
  #     # Attaching the workspaceElement to the DOM is required to allow the
  #     # `toBeVisible()` matchers to work. Anything testing visibility or focus
  #     # requires that the workspaceElement is on the DOM. Tests that attach the
  #     # workspaceElement to the DOM are generally slower than those off DOM.
  #     jasmine.attachToDOM(workspaceElement)
  #
  #     expect(workspaceElement.querySelector('.atom-tracker')).not.toExist()
  #
  #     # This is an activation event, triggering it causes the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'atom-tracker:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       # Now we can test for view visibility
  #       atomTrackerElement = workspaceElement.querySelector('.atom-tracker')
  #       expect(atomTrackerElement).toBeVisible()
  #       atom.commands.dispatch workspaceElement, 'atom-tracker:toggle'
  #       expect(atomTrackerElement).not.toBeVisible()
