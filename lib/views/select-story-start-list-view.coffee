SelectStoryListView = require './select-story-list-view'

FileUtils = require '../services/file-utils'
TrackerUtils = require '../services/tracker-utils'

module.exports = class SelectStoryStartListView extends SelectStoryListView

  initialize: (project) ->
    super
    TrackerUtils.getUnstartedStories project, @handleStories, (=> @panel?.hide())

  filterItems: (story) ->
    # Remove stories the user can't actually start
    if story.story_type is 'release'
      return false
    else if story.story_type is 'feature' and story.estimate is undefined
      return false
    return true

  handleStories: (stories) =>
    super

  confirmed: (item) ->
    @panel?.hide()
    TrackerUtils.startStory item