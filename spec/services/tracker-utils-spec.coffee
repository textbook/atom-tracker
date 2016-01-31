nock = require 'nock'

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
        expect(arg).toEqual 'Failed to connect to Pivotal Tracker.'
        expect(opts).toEqual {icon: 'radio-tower'}
        done = true
      nock(@url, {reqheaders: @options.headers}).get(@options.path)
        .socketDelay(2000).reply(500)
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

  describe 'startStory method', ->
    putPath = null
    story = null

    beforeEach ->
      @options.headers['Content-Type'] = 'application/json'
      @story = {project_id: 1234567, id: 890, name: 'foo'}
      @putPath = '/services/v5/projects/1234567/stories/890'

    it 'should call the appropriate endpoint', ->
      req = nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      TrackerUtils.startStory @story
      req.done()

    it 'should show a success notification when the story is started', ->
      done = false
      spyOn(atom.notifications, 'addSuccess').andCallFake (msg) ->
        expect(msg).toEqual('Started story "foo".')
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(200)
      runs ->
        TrackerUtils.startStory @story
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if the request times out', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual 'Failed to connect to Pivotal Tracker.'
        expect(opts).toEqual {icon: 'radio-tower'}
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@putPath)
        .socketDelay(2000).reply(500)
      runs ->
        TrackerUtils.startStory @story
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if authentication fails', ->
      done = false
      spyOn(atom.notifications, 'addError').andCallFake (arg, opts) ->
        expect(arg).toEqual TrackerUtils.AUTH_FAIL_MSG
        expect(opts).toEqual {icon: 'lock'}
        done = true
      nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(403)
      runs ->
        TrackerUtils.startStory @story
      waitsFor (-> done), 'calls to be complete', 100

    it 'should show an error if anything else fails', ->
      done = false
      errMsg = 'Failed to start story "foo".'
      error = spyOn(atom.notifications, 'addError').andCallFake (arg) ->
        expect(arg).toEqual(errMsg)
        done = true
      req = nock(@url, {reqheaders: @options.headers}).put(@putPath).reply(500)
      runs ->
        TrackerUtils.startStory @story
      waitsFor (-> done), 'calls to be complete', 100
