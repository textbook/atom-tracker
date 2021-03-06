marked = require 'marked'
nock = require 'nock'
{$} = require 'atom-space-pen-views'

FileUtils = require '../../lib/services/file-utils'
TrackerUtils = require '../../lib/services/tracker-utils'

describe 'TrackerUtils', ->
  options = null
  url = null

  beforeEach ->
    atom.config.set 'atom-tracker.trackerToken', 'dummytoken'
    atom.notifications.clear()
    @options = TrackerUtils.defaultOptions()
    @url = 'https://' + @options.host

  describe 'defaultOptions object', ->

    it 'should set up the basic request options', ->
      expect(@options.headers['X-TrackerToken']).toEqual('dummytoken')
      expect(@options.host).toEqual('www.pivotaltracker.com')

  describe 'makeGetRequest method', ->

    beforeEach ->
      @options.path = '/services/v5/endpoint?option=value'

    it 'should call the specified endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).get(@options.path).reply(200)
      TrackerUtils.makeGetRequest @options
      req.done()

    it 'should decode the response and pass to success if the GET succeeds', ->
      done = false
      payload = {dummy: 'payload', for: [1, 2, 3]}
      spiedSuccess = jasmine.createSpy('success_method').andCallFake (arg) ->
        expect(arg).toEqual(payload)
        done = true
      nock(@url, {reqheaders: @options.headers})
        .get(@options.path).reply(200, payload)
      runs ->
        TrackerUtils.makeGetRequest @options, null, spiedSuccess
      waitsFor (-> done), 'calls to be complete', 100

    it 'should call the failure function if the GET fails', ->
      done = false
      spiedFailure = jasmine.createSpy('failure_method').andCallFake ->
        done = true
      nock(@url, {reqheaders: @options.headers}).get(@options.path).reply(500)
      runs ->
        TrackerUtils.makeGetRequest @options, '', null, spiedFailure
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if the request times out', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.CONNECT_FAIL_MSG
        expect(opts.icon).toEqual 'radio-tower'
        done = true
      nock(@url, {reqheaders: @options.headers}).get(@options.path)
        .socketDelay(TrackerUtils.TIMEOUT * 2).reply(500)
      runs ->
        TrackerUtils.makeGetRequest @options, null, null, null
      waitsFor (-> done), 'calls to be complete'

    it 'should show an error if authentication fails', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.AUTH_FAIL_MSG
        expect(opts).toEqual {icon: 'lock'}
        done = true
      req = nock(@url, {reqheaders: @options.headers}).get(@options.path).reply(403)
      runs ->
        TrackerUtils.makeGetRequest @options, '', null, null
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show a generic error if anything else fails', ->
      done = false
      errMsg = 'whoops!'
      error = spyOn(atom.notifications, 'addError').andCallFake (arg) ->
        expect(arg).toEqual(errMsg)
        done = true
      req = nock(@url, {reqheaders: @options.headers}).get(@options.path).reply(500)
      runs ->
        TrackerUtils.makeGetRequest @options, errMsg, null, null
      waitsFor (-> done), 'calls to be complete', 100

  describe 'getProjects method', ->
    endpoint = null

    beforeEach ->
      @endpoint = '/services/v5/me'

    it 'should pass the projects list from the response to success', ->
      done = false
      nock(@url, {reqheaders: @options.headers}).get(@endpoint).reply(200, {projects: ['foo', 'bar']})
      runs -> TrackerUtils.getProjects (res) -> done = true if res.length is 2
      waitsFor -> done

    it 'should pass an empty list to success if no projects in the response', ->
      done = false
      nock(@url, {reqheaders: @options.headers}).get(@endpoint).reply(200, {})
      runs -> TrackerUtils.getProjects (res) -> done = true if res.length is 0
      waitsFor -> done

  describe 'getProjectDetails method', ->

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers})
        .get('/services/v5/projects/1234567?fields=:default,current_velocity')
        .reply(200, {})
      TrackerUtils.getProjectDetails {project_id: 1234567}
      req.done()

  describe 'getUnstartedStories method', ->

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers})
        .get('/services/v5/projects/1234567/stories?with_state=unstarted')
        .reply(200)
      @options.path = '/services/v5/projects/1234567/stories?with_state=unstarted'
      TrackerUtils.getUnstartedStories {id: 1234567, name: 'foo'}
      req.done()

  describe 'makePutRequest method', ->

    beforeEach ->
      @options.path = '/services/v5/projects/1234567/stories/890'

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).put(@options.path).reply(200)
      TrackerUtils.makePutRequest @options, {}
      req.done()

    it 'should show an error if the request times out', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.CONNECT_FAIL_MSG
        expect(opts.icon).toEqual 'radio-tower'
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@options.path)
        .socketDelay(TrackerUtils.TIMEOUT * 2).reply(500)
      runs ->
        TrackerUtils.makePutRequest @options, {}
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if authentication fails', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.AUTH_FAIL_MSG
        expect(opts).toEqual {icon: 'lock'}
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@options.path).reply(403)
      runs ->
        TrackerUtils.makePutRequest @options, {}
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if anything else fails', ->
      done = false
      errMsg = 'Failed to start story "foo"'
      error = spyOn(atom.notifications, 'addError').andCallFake (arg) ->
        expect(arg).toEqual(errMsg)
        done = true
      req = nock(@url, {reqheaders: @options.headers}).put(@options.path).reply(500)
      runs ->
        TrackerUtils.makePutRequest @options, {}, errMsg
      waitsFor (-> done), 'calls to be complete', 100

  describe 'makePostRequest method', ->

    beforeEach ->
      @options.path = '/services/v5/projects/1234567/stories'

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).post(@options.path).reply(200)
      TrackerUtils.makePostRequest @options, {}
      req.done()

    it 'should show an error if the request times out', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.CONNECT_FAIL_MSG
        expect(opts.icon).toEqual 'radio-tower'
        done = true
      nock(@url, {reqheaders: @options.headers}).post(@options.path)
        .socketDelay(TrackerUtils.TIMEOUT * 2).reply(500)
      runs ->
        TrackerUtils.makePostRequest @options, {}
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if authentication fails', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.AUTH_FAIL_MSG
        expect(opts).toEqual {icon: 'lock'}
        done = true
      nock(@url, {reqheaders: @options.headers}).post(@options.path).reply(403)
      runs ->
        TrackerUtils.makePostRequest @options, {}
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if anything else fails', ->
      done = false
      errMsg = 'Failed to start story "foo"'
      error = spyOn(atom.notifications, 'addError').andCallFake (arg) ->
        expect(arg).toEqual(errMsg)
        done = true
      req = nock(@url, {reqheaders: @options.headers}).post(@options.path).reply(500)
      runs ->
        TrackerUtils.makePostRequest @options, {}, errMsg
      waitsFor (-> done), 'calls to be complete', 100

  describe 'startStory method', ->
    putPath = null
    story = null

    beforeEach ->
      @options.headers['Content-Type'] = 'application/json'
      @story = {project_id: 1234567, id: 890, name: 'foo'}
      @putPath = '/services/v5/projects/1234567/stories/890'

    it 'should call the appropriate method', ->
      spyOn(TrackerUtils, 'makePutRequest')
      TrackerUtils.startStory @story
      expect(TrackerUtils.makePutRequest).toHaveBeenCalled()

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      TrackerUtils.startStory @story
      req.done()

    it 'should show a success notification when the story is started', ->
      done = false
      spyOn(atom.notifications, 'addSuccess').andCallFake (msg) ->
        expect(msg).toEqual('Started story "foo"')
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      runs ->
        TrackerUtils.startStory @story
      waitsFor (-> done), 'calls to be complete', 100

  describe 'createStory method', ->
    postPath = null
    projectId = null
    story = null

    beforeEach ->
      @options.headers['Content-Type'] = 'application/json'
      @postPath = '/services/v5/projects/1234567/stories'
      @projectId = 1234567
      @story = {name: 'foo', story_type: 'bar'}

    it 'should call the appropriate method', ->
      spyOn(TrackerUtils, 'makePostRequest')
      TrackerUtils.createStory @projectId, @story
      expect(TrackerUtils.makePostRequest).toHaveBeenCalled()

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).post(@postPath).reply(200)
      TrackerUtils.createStory @projectId, @story
      req.done()

    it 'should show a failure notification when the story isn\'t created', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (msg) ->
        expect(msg).toEqual('Failed to create story "foo"')
        done = true
      req = nock(@url, {reqheaders: @options.headers}).post(@postPath).reply(400)
      TrackerUtils.createStory @projectId, @story
      waitsFor (-> done), 'calls to be complete', 100

  describe 'finishStory method', ->
    putPath = null
    story = null

    beforeEach ->
      @options.headers['Content-Type'] = 'application/json'
      @story = {project_id: 1234567, id: 890, name: 'foo'}
      @putPath = '/services/v5/projects/1234567/stories/890'
      spyOn(FileUtils, 'eraseComment')

    it 'should call the appropriate method', ->
      spyOn(TrackerUtils, 'makePutRequest')
      TrackerUtils.finishStory @story
      expect(TrackerUtils.makePutRequest).toHaveBeenCalled()

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      TrackerUtils.startStory @story
      req.done()

    it 'should show a success notification when the story is finished', ->
      done = false
      spyOn(atom.notifications, 'addSuccess').andCallFake (msg) ->
        expect(msg).toEqual('Finished story "foo"')
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      runs ->
        TrackerUtils.finishStory @story
      waitsFor (-> done), 'calls to be complete', 100

    it 'should erase the comment', ->
      spyOn(TrackerUtils, 'updateStory').andCallFake (_, __, ___, success) ->
        success()
      story = {description: 'hello'}
      TrackerUtils.finishStory story
      expect(FileUtils.eraseComment).toHaveBeenCalledWith story

    it 'should not attempt to erase if the story has no description', ->
      spyOn(TrackerUtils, 'updateStory').andCallFake (_, __, ___, success) ->
        success()
      TrackerUtils.finishStory {}
      expect(FileUtils.eraseComment).not.toHaveBeenCalled()

  describe 'appropriateIcon method', ->

    it 'should return star as a default', ->
      expect(TrackerUtils.appropriateIcon 'foo').toEqual 'star'

    it 'should return bug for a bug story', ->
      expect(TrackerUtils.appropriateIcon 'bug').toEqual 'bug'

    it 'should return gear for a chore story', ->
      expect(TrackerUtils.appropriateIcon 'chore').toEqual 'gear'

  describe 'showStoryInfo method', ->
    story = null

    beforeEach ->
      spyOn(atom.notifications, 'addInfo')
      @story =
        description: '**markdown** *formatted*'
        name: 'foo'
        story_type: 'chore'

    it 'should show an info notification', ->
      TrackerUtils.showStoryInfo 'Testing', @story
      expect(atom.notifications.addInfo).toHaveBeenCalledWith '<strong>Testing</strong>: foo',
        detail: 'replace me'
        dismissable: true
        icon: 'gear'

    it 'should replace the notification details with formatted HTML', ->
      expectedHtml = '<p><strong>markdown</strong> <em>formatted</em></p>'
      spied = spyOn($.fn, 'empty').andReturn
        append: (val) ->
          expect(val[0].outerHTML).toEqual expectedHtml
      TrackerUtils.showStoryInfo 'Testing', @story
      expect(spied).toHaveBeenCalled()
