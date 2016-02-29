SelectStoryStartListView = require '../../lib/views/select-story-start-list-view'
TrackerUtils = require '../../lib/services/tracker-utils'

describe 'SelectStoryStartListView', ->
  view = null

  beforeEach ->
    spyOn(TrackerUtils, 'getUnstartedStories')
    @view = new SelectStoryStartListView

  it 'should call getUnstartedStories', ->
    expect(TrackerUtils.getUnstartedStories).toHaveBeenCalled()

  describe 'confirmed method', ->
    item = null

    beforeEach ->
      @item =
        foo: 'bar'

    it 'should call startStory with the selected item', ->
      spyOn(TrackerUtils, 'startStory')
      @view.confirmed @item
      expect(TrackerUtils.startStory).toHaveBeenCalledWith @item

    it 'should show the information on the started story', ->
      spyOn(TrackerUtils, 'showStoryInfo')
      @view.confirmed @item
      expect(TrackerUtils.showStoryInfo).toHaveBeenCalledWith 'Starting', @item

  describe 'filterItems method', ->

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
