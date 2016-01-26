nock = require 'nock'

CreateConfigView = require '../lib/create-config-view'

options =
  reqheaders: {'X-TrackerToken': 'dummytoken'}

describe 'CreateConfigView', ->
  view = null

  describe 'getProjects method', ->
    failure = null
    success = null
    view = null

    beforeEach ->
      atom.config.set 'atom-tracker.trackerToken',
        options.reqheaders['X-TrackerToken']
      @view = new CreateConfigView
      atom.notifications.clear()
      @success = jasmine.createSpy('success')
      @failure = jasmine.createSpy('failure')

    it 'calls GET on the Tracker API endpoint', ->
      nock('https://www.pivotaltracker.com', options)
        .get('/services/v5/me')
        .reply(200, {})
      @view.getProjects(@success, @failure)

    it 'calls the success function with the payload when the GET succeeds', ->
      payload = {dummy: 'data', projects: ['foo', 'bar']}
      done = false
      spiedSuccess = jasmine.createSpy('spiedSuccess').andCallFake (result) ->
        if result.length is 2 and result[0] is 'foo' and result[1] is 'bar'
          done = true
      mockRoute = nock('https://www.pivotaltracker.com', options)
        .get('/services/v5/me')
        .reply(200, payload)
      runs ->
        @view.getProjects(spiedSuccess, @failure)
      waitsFor (-> done), 'success function to be called with payload', 250
      expect(@failure).not.toHaveBeenCalled()

    it 'calls the failure function when the GET fails', ->
      nock('https://www.pivotaltracker.com', options)
        .get('/services/v5/me')
        .reply(500)
      runs ->
        @view.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows a warning if authentication fails', ->
      warning = spyOn(atom.notifications, 'addWarning')
      nock('https://www.pivotaltracker.com', options)
        .get('/services/v5/me')
        .reply(403)
      runs ->
        @view.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> warning.wasCalled), 'warning message to be shown', 100
      expect(@success).not.toHaveBeenCalled()

    it 'shows an error if anything else fails', ->
      spyOn(atom.notifications, 'addWarning')
      error = spyOn(atom.notifications, 'addError')
      nock('https://www.pivotaltracker.com', options)
        .get('/services/v5/me')
        .reply(500)
      runs ->
        @view.getProjects(@success, @failure)
      waitsFor (-> @failure.wasCalled), 'failure function to be called', 100
      waitsFor (-> error.wasCalled), 'error message to be shown', 100
      expect(@success).not.toHaveBeenCalled()
