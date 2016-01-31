AtomTracker = require '../lib/atom-tracker'

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

  testCases = [
    'atom-tracker.colorizeStatusBar'
    'atom-tracker.showStatusBar'
    'atom-tracker.velocityStatusBar'
  ]

  for testCase in testCases
    describe "when the #{testCase} config is changed", ->

      it 'refreshes the status bar', ->
        atom.config.set testCase, true
        spyOn(AtomTracker, 'refreshStatusBar')
        atom.config.set testCase, false
        expect(AtomTracker.refreshStatusBar).toHaveBeenCalled()

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
