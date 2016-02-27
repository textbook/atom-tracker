StoryView = require '../../lib/views/story-view'

TrackerUtils = require '../../lib/services/tracker-utils'

describe 'StoryView', ->
  view = null

  beforeEach ->
    @view = new StoryView

  describe 'validateStory method', ->

    beforeEach ->
      spyOn(atom.notifications, 'addWarning')

    it 'should return true if both name and type are present', ->
      expect(@view.validateStory {name: 'yes', story_type: 'yes'}).toBeTruthy()

    it 'should return false and show a warning if name is missing', ->
      expect(@view.validateStory {story_type: 'yes'}).toBeFalsy()
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'Title required to create story'
      )

    it 'should return false and show a warning if type is missing', ->
      expect(@view.validateStory {name: 'yes'}).toBeFalsy()
      expect(atom.notifications.addWarning).toHaveBeenCalledWith(
        'Story type required to create story'
      )

  describe 'appropriateIcon method', ->

    it 'should use the current type if none is provided', ->
      spyOn(@view, 'currentType')

      @view.appropriateIcon()

      expect(@view.currentType).toHaveBeenCalled()

    it 'should return star as a default', ->
      expect(@view.appropriateIcon 'foo').toEqual 'star'

    it 'should return bug for a bug story', ->
      expect(@view.appropriateIcon 'bug').toEqual 'bug'

    it 'should return gear for a chore story', ->
      expect(@view.appropriateIcon 'chore').toEqual 'gear'

  describe 'createStory method', ->

    beforeEach ->
      @view.projectData = {project: {id: 1234567}}
      @view.story.description = 'description'
      spyOn(@view, 'validateStory').andReturn true
      spyOn(@view.storyTitleInput, 'getText').andReturn 'name'
      spyOn(@view, 'currentType').andReturn 'bug'

    it 'should get and validate the story', ->
      spyOn(TrackerUtils, 'createStory')

      @view.createStory()

      expect(@view.storyTitleInput.getText).toHaveBeenCalled()
      expect(@view.currentType).toHaveBeenCalled()
      expect(@view.validateStory).toHaveBeenCalledWith
        description: 'description'
        name: 'name'
        story_type: 'bug'

    it 'should delegate to the createStory method in TrackerUtils', ->
      spyOn(TrackerUtils, 'createStory')

      @view.createStory()

      expect(TrackerUtils.createStory).toHaveBeenCalled()

    it 'should call createSuccess on success', ->
      spyOn(TrackerUtils, 'createStory').andCallFake (id, story, func) =>
        spyOn(@view, 'createSuccess')
        func {}
        expect(@view.createSuccess).toHaveBeenCalledWith {}, undefined

      @view.createStory()

  describe 'createSuccess method', ->
    data = null

    beforeEach ->
      @data = {story_type: 'foo', id: 123456789, name: 'bar'}
      spyOn(atom.notifications, 'addSuccess')
      spyOn(@view, 'appropriateIcon').andReturn 'baz'

    it 'should show a success notification with the appropriate icon', ->
      @view.createSuccess @data

      expect(@view.appropriateIcon).toHaveBeenCalled()
      expect(atom.notifications.addSuccess).toHaveBeenCalledWith(
        'Created foo "bar" [#123456789]', {icon: 'baz'}
      )

    it 'should call the success function if provided', ->
      callback = jasmine.createSpy('callback').andCallFake (data) =>
        expect(data).toEqual @data
      @view.createSuccess @data, callback

  describe 'updateIcon method', ->
    finder = null

    beforeEach ->
      @finder =
        addClass: jasmine.createSpy('addClass')
        removeClass: null
      spyOn(@view, 'find').andReturn @finder
      spyOn(@view, 'appropriateIcon').andReturn 'bar'

    it 'should find the element for the specified selector', ->
      spyOn(@finder, 'removeClass')

      @view.updateIcon 'foo'

      expect(@view.find).toHaveBeenCalledWith 'foo'

    it 'should remove previous icon classes', ->
      spyOn(@finder, 'removeClass').andCallFake (func) ->
        expect(func null, 'one icon-foo two icon-bar three').toEqual(
          'icon-foo icon-bar'
        )
      @view.updateIcon 'foo'

    it 'should add the appropriate icon class', ->
      spyOn(@finder, 'removeClass')

      @view.updateIcon 'chore'

      expect(@view.appropriateIcon).toHaveBeenCalled()
      expect(@finder.addClass).toHaveBeenCalledWith('icon-bar')
