nock = require 'nock'

TrackerUtils = require '../lib/tracker-utils'

describe 'TrackerUtils', ->
  options =
    reqheaders: {'X-TrackerToken': 'dummytoken'}
  url = 'https://www.pivotaltracker.com'

  failure = null
  success = null

  beforeEach ->
    atom.config.set 'atom-tracker.trackerToken',
      options.reqheaders['X-TrackerToken']
    atom.notifications.clear()
    @success = jasmine.createSpy('success')
    @failure = jasmine.createSpy('failure')

  describe 'getProjects method', ->
    endpoint = '/services/v5/me'

    beforeEach ->
      atom.config.set 'atom-tracker.trackerToken',
        options.reqheaders['X-TrackerToken']
      atom.notifications.clear()
      @success = jasmine.createSpy('success')
      @failure = jasmine.createSpy('failure')

    it 'calls GET on the Tracker API endpoint', ->
      nock(url, options).get(endpoint).reply(200, {})
      TrackerUtils.getProjects(@success, @failure)

    it 'calls the success function with the payload when the GET succeeds', ->
      payload = {dummy: 'data', projects: ['foo', 'bar']}
      done = false
      spiedSuccess = jasmine.createSpy('spiedSuccess').andCallFake (result) ->
        if result.length is 2 and result[0] is 'foo' and result[1] is 'bar'
          done = true
      mockRoute = nock(url, options).get(endpoint).reply(200, payload)
      runs ->
        TrackerUtils.getProjects(spiedSuccess, @failure)
      waitsFor (-> done), 'success function to be called with payload', 250
      expect(@failure).not.toHaveBeenCalled()

    it 'calls the failure function when the GET fails', ->
      nock(url, options).get(endpoint).reply(500)
      runs ->
        TrackerUtils.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows a warning if authentication fails', ->
      warning = spyOn(atom.notifications, 'addWarning')
      nock(url, options).get(endpoint).reply(403)
      runs ->
        TrackerUtils.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> warning.wasCalled), 'warning message to be shown', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows an error if anything else fails', ->
      spyOn(atom.notifications, 'addWarning')
      error = spyOn(atom.notifications, 'addError')
      nock(url, options).get(endpoint).reply(500)
      runs ->
        TrackerUtils.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> error.wasCalled), 'error message to be shown', 100
      expect(@success).not.toHaveBeenCalled()

  describe 'getProjectDetails method', ->

    endpoint = '/services/v5/projects/1234567?fields=:default,current_velocity'
    project = {project_id: 1234567, name: 'foobar'}

    it 'should call GET on the Tracker API endpoint', ->
      nock(url, options).get(endpoint).reply(200, {})
      TrackerUtils.getProjectDetails(project, @success, @failure)

    it 'calls the success function with the payload when the GET succeeds', ->
      payload = {dummy: 'data', for: 'project'}
      done = false
      spiedSuccess = jasmine.createSpy('spiedSuccess').andCallFake (result) ->
        if result.dummy is 'data' and result.for is 'project'
          done = true
      mockRoute = nock(url, options).get(endpoint).reply(200, payload)
      runs ->
        TrackerUtils.getProjectDetails(project, spiedSuccess, @failure)
      waitsFor (-> done), 'success function to be called with payload', 250
      expect(@failure).not.toHaveBeenCalled()

    it 'calls the failure function when the GET fails', ->
      nock(url, options).get(endpoint).reply(500)
      runs ->
        TrackerUtils.getProjectDetails(project, @success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows a warning if authentication fails', ->
      warning = spyOn(atom.notifications, 'addWarning')
      nock(url, options).get(endpoint).reply(403)
      runs ->
        TrackerUtils.getProjectDetails(project, @success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> warning.wasCalled), 'warning message to be shown', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows an error if anything else fails', ->
      spyOn(atom.notifications, 'addWarning')
      error = spyOn(atom.notifications, 'addError')
      nock(url, options).get(endpoint).reply(500)
      runs ->
        TrackerUtils.getProjectDetails(project, @success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> error.wasCalled), 'error message to be shown', 100
      expect(@success).not.toHaveBeenCalled()
