SelectStoryListView = require './select-story-list-view'

FileUtils = require '../services/file-utils'
TrackerUtils = require '../services/tracker-utils'

module.exports = class SelectStoryFinishListView extends SelectStoryListView

  initialize: (project) ->
    super project
    TrackerUtils.getStartedStories project, @handleStories, (=> @panel?.hide())

  handleStories: (stories) =>
    super

  filterItems: (story) ->
    return true

  confirmed: (item) ->
    @panel?.hide()
    TrackerUtils.finishStory item
