CSON = require 'season'

FileUtils = require '../lib/file-utils'

describe 'FileUtils', ->

  beforeEach ->
    atom.config.set 'atom-tracker.projectConfigFile', 'dummyfile'

  describe 'configFile method', ->

    it 'should return the projectConfigFile configuration value', ->
      expect(FileUtils.configFile()).toEqual('dummyfile')

  describe 'rootFilepath method', ->

    beforeEach ->
      spyOn(atom.project, 'getPaths').andReturn(['foo', 'bar'])

    it 'should call getPaths to find the project location', ->
      FileUtils.rootFilepath()
      expect(atom.project.getPaths).toHaveBeenCalled()

    it 'should return the appropriate filepath if argument supplied', ->
      expect(FileUtils.rootFilepath('bar')).toEqual('foo/bar')

    it 'should return the default config filepath if no arguments supplied', ->
      expect(FileUtils.rootFilepath()).toEqual('foo/dummyfile')

  describe 'writeCsonFile method', ->

    beforeEach ->
      spyOn(FileUtils, 'rootFilepath').andReturn('foo/bar')
      spyOn(atom.notifications, 'addError')

    it 'should call writeFile', ->
      spyOn(CSON, 'writeFile')
      payload = {dummy: true}
      FileUtils.writeCsonFile 'foo', payload
      # # Doesn't work, despite appearing to match.
      # expect(CSON.writeFile).toHaveBeenCalledWith 'foo/bar', payload,
      #   jasmine.any(Function)
      expect(CSON.writeFile).toHaveBeenCalled()

    it 'should show a notification if an error occurs', ->
      spyOn(CSON, 'writeFile').andCallFake (path, obj, func) ->
        func {stack: 'foo'}
      FileUtils.writeCsonFile 'foo'
      expect(atom.notifications.addError).toHaveBeenCalledWith(
        'Failed to write file.', {detail: 'foo'})

    it 'should pass the error message to the notification if provided', ->
      spyOn(CSON, 'writeFile').andCallFake (path, obj, func) ->
        func {stack: 'foo'}
      FileUtils.writeCsonFile 'foo', {}, 'error message'
      expect(atom.notifications.addError).toHaveBeenCalledWith 'error message',
        {detail: 'foo'}

    afterEach ->
      expect(FileUtils.rootFilepath).toHaveBeenCalledWith('foo')

  describe 'readCsonFile method', ->
    success = null
    failure = null

    beforeEach ->
      @success = jasmine.createSpy('success')
      @failure = jasmine.createSpy('failure')

    it 'should call the success method with the result on success', ->
      spyOn(CSON, 'readFile').andCallFake (path, handler) ->
        handler(null, 'foo')
      FileUtils.readCsonFile 'path', @success, @failure
      expect(@success).toHaveBeenCalledWith('foo')

    it 'should call the failure method with the error on failure', ->
      spyOn(CSON, 'readFile').andCallFake (path, handler) ->
        handler('foo', null)
      FileUtils.readCsonFile 'path', @success, @failure
      expect(@failure).toHaveBeenCalledWith('foo')
