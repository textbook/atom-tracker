SelectStoryListView = require './select-story-list-view'

FileUtils = require '../services/file-utils'
TrackerUtils = require '../services/tracker-utils'

module.exports = class SelectStoryStartListView extends SelectStoryListView

  initialize: (project) ->
    super project
    @setPlaceholder 'Start the selected story'
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
    if atom.config.get 'atom-tracker.showStoryDetails'
      TrackerUtils.showStoryInfo 'Starting', item
    TrackerUtils.startStory item
