AtomTrackerView = require './atom-tracker-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomTracker =
  config:
    trackerId:
      type: 'integer'
      minimum: 1
  atomTrackerView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomTrackerView = new AtomTrackerView(state.atomTrackerViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomTrackerView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-tracker:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomTrackerView.destroy()

  serialize: ->
    atomTrackerViewState: @atomTrackerView.serialize()

  toggle: ->
    console.log 'AtomTracker was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
