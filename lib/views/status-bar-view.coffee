class StatusBarView extends HTMLElement
  iconSpan = null
  textLink = null
  velocitySpan = null

  createdCallback: ->
    @classList.add('tracker-status')
    @classList.add('inline-block')

    @iconSpan = document.createElement('span')
    @iconSpan.classList.add('icon')
    @iconSpan.classList.add('icon-graph')
    @appendChild(@iconSpan)

    textSpan = document.createElement('span')
    textSpan.classList.add 'atom-tracker-name'
    @textLink = document.createElement('a')
    textSpan.appendChild(@textLink)
    @appendChild(textSpan)

    @velocitySpan = document.createElement('span')
    @velocitySpan.classList.add('badge')
    @velocitySpan.classList.add('badge-small')
    @appendChild(@velocitySpan)

  display: (shown) ->
    if shown
      @removeAttribute 'hidden'
    else
      @setAttribute 'hidden', true

  updateContent: (data) ->
    color = null
    if atom.config.get 'atom-tracker.colorizeStatusBar'
      color = "##{data.membership_summary.project_color}"
    if atom.config.get 'atom-tracker.velocityStatusBar'
      @velocitySpan.removeAttribute 'hidden'
    else
      @velocitySpan.setAttribute 'hidden', true
    @textLink.style.color = color
    @iconSpan.style.color = color
    @textLink.setAttribute 'href',
      "https://www.pivotaltracker.com/n/projects/#{data.project.id}"
    @textLink.textContent = "#{data.project.name}"
    @velocitySpan.textContent = "#{data.project.current_velocity}"

module.exports = document.registerElement 'atom-tracker-status',
  prototype: StatusBarView.prototype
