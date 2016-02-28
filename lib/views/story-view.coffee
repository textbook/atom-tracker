{TextEditorView, View} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

TrackerUtils = require '../services/tracker-utils'

module.exports =
class StoryView extends View
  projectData = null
  story = null
  success = null

  @content: ->
    @div class: 'atom-tracker tracker-story create-pane settings-view', =>
      @div class: 'section settings-panel tracker-story-section', is: 'space-pen-section', =>
        @span class: 'inline-control select-type', =>
          @select class: 'form-control story-type', outlet: 'storyType', =>
            for option in ['Feature', 'Chore', 'Bug']
              @option value: option.toLowerCase(), option
        @span class: 'inline-control story-name', =>
          @subview 'storyTitleInput', new TextEditorView
            mini: true
            outlet: 'storyTitle'
            placeholderText: 'Story name'
        @span class: 'inline-control submit-button', =>
          @button ' Create Story',
            class: 'create-btn btn icon-star story-type-icon'
            outlet: 'createButton'
            type: 'button'

  initialize: (@projectData, story, @success) ->
    oldView?.destroy()
    oldView = this

    @story = story or {}

    @storyType.on 'change', =>
      @updateIcon ".create-btn"
      @storyTitleInput.focus()
    @createButton.on 'click', => @createStory()

    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add '.story-name',
      'core:focus-previous': =>
        @storyType.focus()
      'core:focus-next': =>
        @createButton.focus()
      'core:confirm': =>
        @createStory()
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel': =>
        return if @hidden
        @destroy()

    atom.workspace.addBottomPanel item: this

    @storyTitleInput.setText @story.name or ''
    @storyType.val @story.story_type or 'feature'
    @updateIcon ".create-btn"
    @storyTitleInput.focus()

  updateIcon: (selector) ->
    el = this.find selector
    el.removeClass (index, css) ->
      return css.match(/\b(icon-\S+)/g or []).join ' '
    el.addClass 'icon-' + TrackerUtils.appropriateIcon @currentType()

  createStory: ->
    @story.name = @storyTitleInput.getText()
    @story.story_type = @currentType()
    successCallback = @success
    if @validateStory(@story)
      TrackerUtils.createStory @projectData.project.id, @story,
        ((data) => @createSuccess data, successCallback)
      @destroy()

  createSuccess: (data, callback) ->
    atom.notifications.addSuccess "Created #{data.story_type} " +
      "\"#{data.name}\" [##{data.id}]", {
        icon: TrackerUtils.appropriateIcon data.story_type
      }
    callback? data

  currentType: ->
    @storyType[0].selectedOptions[0].value

  validateStory: (story) ->
    if not story.name
      atom.notifications.addWarning 'Title required to create story'
      return false
    else if not story.story_type
      atom.notifications.addWarning 'Story type required to create story'
      return false
    return true

  destroy: ->
    @projectData = null
    @story = null
    @success = null
    @disposables.dispose()
    @detach()

  show: ->
    @hidden = false
    @css(display: 'inline-block')
