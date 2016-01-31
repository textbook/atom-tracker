SelectProjectListView = require '../../lib/views/select-project-list-view'
FileUtils = require '../../lib/services/file-utils'
TrackerUtils = require '../../lib/services/tracker-utils'

describe 'SelectProjectListView', ->
  view = null

  beforeEach ->
    spyOn(TrackerUtils, 'getProjects')

  describe 'initialize method', ->

    it 'calls getProject', ->
      view = new SelectProjectListView
      expect(TrackerUtils.getProjects).toHaveBeenCalled()

  describe 'confirmed method', ->

    beforeEach ->
      @view = new SelectProjectListView

    it 'should get the full project details', ->
      spyOn(TrackerUtils, 'getProjectDetails')
      item = {foo: 'bar'}
      @view.confirmed item
      expect(TrackerUtils.getProjectDetails).toHaveBeenCalled()
      args = TrackerUtils.getProjectDetails.calls[0].args
      expect(args[0]).toEqual(item)

    it 'should save the details to a file', ->
      data = {baz: 'foo'}
      item = {foo: 'bar'}
      spyOn(TrackerUtils, 'getProjectDetails').andCallFake (item, success) ->
        success(data)
      spyOn(FileUtils, 'writeCsonFile')
      @view.confirmed item
      expect(FileUtils.writeCsonFile).toHaveBeenCalled()
      args = FileUtils.writeCsonFile.calls[0].args
      expect(args[1]).toEqual({project: data, membership_summary: item})
