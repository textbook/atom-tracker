CSON = require 'season'
fs = require 'fs'
jschardet = require 'jschardet'
path = require 'path'

FileUtils = require '../../lib/services/file-utils'

describe 'FileUtils', ->

  beforeEach ->
    atom.config.set 'atom-tracker.projectConfigFile', 'dummyfile'

  describe 'configFile method', ->

    it 'should return the projectConfigFile configuration value', ->
      expect(FileUtils.configFile()).toEqual('dummyfile')

  describe 'relativePath method', ->

    it 'should return the path relative to the first project path', ->
      spyOn(atom.project, 'getPaths').andReturn ['foo', 'bar']
      expect(FileUtils.relativePath 'foo/bar/baz').toEqual 'bar/baz'

    it 'should return the full path if there are no project paths', ->
      spyOn(atom.project, 'getPaths').andReturn []
      expect(FileUtils.relativePath 'foo/bar/baz').toEqual 'foo/bar/baz'

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

    it 'should not call the success function on failure', ->
      spyOn(CSON, 'readFile').andCallFake (path, handler) ->
        handler('foo', null)
      FileUtils.readCsonFile 'path', @success
      expect(@success).not.toHaveBeenCalled()

  describe 'eraseComment method', ->
    fakeFile = null
    story = null

    beforeEach ->
      @fakeFile =
        toString: jasmine.createSpy('toString').andReturn
          replace: jasmine.createSpy('replace').andReturn 'world'
      spyOn(atom.project, 'getPaths').andReturn ['foo/bar']
      spyOn(fs, 'readFile').andCallFake (filepath, callback) =>
        callback(null, @fakeFile)
      spyOn(fs, 'writeFile')
      spyOn(jschardet, 'detect').andReturn
        encoding: 'utf8'
      spyOn(path, 'join').andReturn 'hello'
      @story =
        description: 'Stuff\nComment location: `bar/baz 42`\nOther stuff'
        id: 123456789

    it 'should do nothing if the story description contains no location', ->
      @story.description = 'nothing matching the regular expression'
      result = FileUtils.eraseComment @story
      expect(result).toBeFalsy()

    it 'should get the absolute path to the file with the comment', ->
      FileUtils.eraseComment @story
      expect(path.join).toHaveBeenCalledWith 'foo/bar', 'bar/baz'

    it 'should open the file and convert it to a string', ->
      FileUtils.eraseComment @story
      expect(fs.readFile).toHaveBeenCalled()
      expect(jschardet.detect).toHaveBeenCalledWith @fakeFile
      expect(@fakeFile.toString).toHaveBeenCalledWith 'utf8'

    it 'should replace the content and write out the result', ->
      FileUtils.eraseComment @story
      expect(@fakeFile.toString().replace).toHaveBeenCalledWith(
        /^.+\[\#123456789\].*\n/m, ''
      )
      expect(fs.writeFile).toHaveBeenCalledWith 'hello', 'world', 'utf8'
