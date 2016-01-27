nock = require 'nock'

CreateConfigView = require '../lib/create-config-view'
TrackerUtils = require '../lib/tracker-utils'

describe 'CreateConfigView', ->
  view = null

  beforeEach ->
    spyOn(TrackerUtils, 'getProjects')

  describe 'initialize method', ->

    it 'calls getProject', ->
      view = new CreateConfigView
      expect(TrackerUtils.getProjects).toHaveBeenCalled()
