NextStoryView = require '../../lib/views/next-story-view'
TrackerUtils = require '../../lib/services/tracker-utils'

describe 'NextStoryView', ->

  describe 'handleStories method', ->

    beforeEach ->
      spyOn(TrackerUtils, 'getUnstartedStories')
      @view = new NextStoryView

    it 'should filter the stories', ->
      spyOn(@view, 'setItems')
      stories = [{story_type: 'chore'}]
      spyOn(@view, 'filterItems').andCallThrough()
      @view.handleStories stories
      expect(@view.filterItems).toHaveBeenCalledWith(stories[0], 0, stories)

    it 'should call setItems with filtered stories', ->
      spyOn(@view, 'setItems')
      stories = [{story_type: 'chore'}]
      spyOn(@view, 'filterItems').andReturn(stories)
      @view.handleStories stories
      expect(@view.setItems).toHaveBeenCalledWith(stories)

    it 'should show a warning if there are no filtered stories', ->
      spyOn(atom.notifications, 'addWarning')
      @view.project = {name: 'foo'}
      expected = 'No unstarted stories in the "foo" backlog'
      @view.handleStories []
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(expected)

  describe 'configureItem method', ->

    beforeEach ->
      atom.config.set 'atom-tracker.showFeatureEstimate', false
      spyOn(TrackerUtils, 'getUnstartedStories')
      @view = new NextStoryView

    it 'should set the appropriate default values', ->
      config = @view.configureItem {story_type: 'foo', name: 'bar'}
      expect(config.iconClass).toEqual('icon-star')
      expect(config.pointSpan).toEqual('')
      expect(config.name).toEqual('bar')

    it 'should show a bug icon for bugs', ->
      config = @view.configureItem {story_type: 'bug', name: 'bar'}
      expect(config.iconClass).toEqual('icon-bug')

    it 'should show a gear icon for chores', ->
      config = @view.configureItem {story_type: 'chore', name: 'bar'}
      expect(config.iconClass).toEqual('icon-gear')

    it 'should provide a pointSpan for features if configured to do so', ->
      atom.config.set 'atom-tracker.showFeatureEstimate', true
      config = @view.configureItem {story_type: 'feature', name: 'bar'}
      expect(config.pointSpan).not.toEqual('')

    it 'should truncate and ellipse overly-long story names', ->
      @view.MAX_LEN = 10
      config = @view.configureItem {story_type: 'feature', name: 'foo bar baz'}
      expect(config.name).toEqual('foo bar...')

  describe 'confirmed method', ->
    view = null

    beforeEach ->
      spyOn(TrackerUtils, 'getUnstartedStories')
      spyOn(TrackerUtils, 'startStory')
      @view = new NextStoryView

    it 'should call startStory with the selected item', ->
      item = {foo: 'bar'}
      @view.confirmed item
      expect(TrackerUtils.startStory).toHaveBeenCalledWith(item)

  describe 'filterItems method', ->
    view = null

    beforeEach ->
      spyOn(TrackerUtils, 'getUnstartedStories')
      @view = new NextStoryView

    testCases = [
      {
        name: 'should return true for estimated features'
        story: {story_type: 'feature', estimate: 0}
        expected: true
      },
      {
        name: 'should return true for bugs'
        story: {story_type: 'bug'}
        expected: true
      },
      {
        name: 'should return true for estimated features'
        story: {story_type: 'chore'}
        expected: true
      },
      {
        name: 'should return false for releases'
        story: {story_type: 'release'}
        expected: false
      },
      {
        name: 'should return false for unestimated features'
        story: {story_type: 'feature'}
        expected: false
      }
    ]

    for testCase in testCases
      it testCase.name, ->
        expect(@view.filterItems testCase.story).toBe(testCase.expected)
