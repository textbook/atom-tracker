SelectStoryListView = require '../../lib/views/select-story-list-view'

describe 'SelectStoryListView', ->

  describe 'handleStories method', ->

    beforeEach ->
      @view = new SelectStoryListView
      @view.filterItems = (item) -> true

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
      spyOn(@view, 'setError')
      @view.project = {name: 'Foo'}
      @view.handleStories []
      expect(@view.setError).toHaveBeenCalledWith('No matching stories in ' +
        'the Foo backlog')


  describe 'configureItem method', ->

    beforeEach ->
      atom.config.set 'atom-tracker.showFeatureEstimate', false
      @view = new SelectStoryListView

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
