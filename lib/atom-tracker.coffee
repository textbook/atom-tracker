{CompositeDisposable} = require 'atom'

CreateConfigView = require './create-config-view'
FileUtils = require './file-utils'

module.exports = AtomTracker =
  currentProject: {}
  state: null
  subscriptions: null

  config:
    trackerToken:
      title: 'Tracker API Token'
      type: 'string'
      description: 'Your access token for the Tracker API. Find it online at ' +
        'https://www.pivotaltracker.com/profile.'
      default: ''
    projectConfigFile:
      title: 'Project-specific configuration file name'
      type: 'string'
      description: 'This file will store the project-specific configuration, ' +
        'e.g. project Tracker ID, in your root project directory.'
      default: '.tracker.cson'

  activate: (state) ->
    @state = state
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'atom-tracker:create-config': => @createProjectConfig()
      @subscriptions.add atom.commands.add 'atom-workspace',
        'atom-tracker:read-config': => @readProjectConfig()

  createProjectConfig: ->
    new CreateConfigView(@state.atomTrackerViewState).reveal()

  readProjectConfig: ->
    FileUtils.readCsonFile FileUtils.rootFilepath(),
      ((results) => @currentProject = results.currentProject),
      ((error) -> atom.notifications.addError 'No project configuration file ' +
        'found.', {icon: 'file-text', detail: error.stack})

  deactivate: ->
    @subscriptions.dispose()
    @atomTrackerView.destroy() if @atomTrackerView

  serialize: ->
    if @atomTrackerView
      atomTrackerViewState: @atomTrackerView.serialize()
