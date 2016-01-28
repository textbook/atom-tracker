class StatusBarView extends HTMLElement
  iconSpan = null
  textLink = null

  createdCallback: ->
    @classList.add('inline-block')

    @iconSpan = document.createElement('span')
    @iconSpan.classList.add('icon')
    @iconSpan.classList.add('icon-graph')
    @appendChild(@iconSpan)

    @textLink = document.createElement('a')
    @textLink.classList.add('atom-tracker-name')
    @appendChild(@textLink)

  display: (shown) ->
    if shown
      @removeAttribute 'hidden'
    else
      @setAttribute 'hidden', true

  updateContent: (project) ->
    color = null
    if atom.config.get 'atom-tracker.colorizeStatusBar'
      color = "##{project.project_color}"
    @textLink.style.color = color
    @iconSpan.style.color = color
    @textLink.setAttribute 'href',
      "https://www.pivotaltracker.com/n/projects/#{project.project_id}"
    @textLink.textContent = "#{project.project_name}"

module.exports = document.registerElement 'atom-tracker-status',
  prototype: StatusBarView.prototype
