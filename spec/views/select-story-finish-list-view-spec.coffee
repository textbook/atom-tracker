SelectStoryFinishListView = require '../../lib/views/select-story-finish-list-view'
TrackerUtils = require '../../lib/services/tracker-utils'

describe 'SelectStoryFinishListView', ->
  view = null

  beforeEach ->
    spyOn(TrackerUtils, 'getStartedStories')
    @view = new SelectStoryFinishListView

  it 'should call getStartedStories', ->
    expect(TrackerUtils.getStartedStories).toHaveBeenCalled()

  describe 'confirmed method', ->

    it 'should call finishStory with the selected item', ->
      spyOn(TrackerUtils, 'finishStory')
      item = {foo: 'bar'}
      @view.confirmed item
      expect(TrackerUtils.finishStory).toHaveBeenCalledWith(item)

  describe 'filterItems method', ->

    testCases = [
      {
        name: 'should return true for any story'
        story: {}
        expected: true
      }
    ]

    for testCase in testCases
      it testCase.name, ->
        expect(@view.filterItems testCase.story).toBe(testCase.expected)
