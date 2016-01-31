StatusBarView = require '../../lib/views/status-bar-view'

describe 'StatusBarView', ->

  describe 'createdCallback method', ->
    view = null

    beforeEach ->
      Object.values = (obj) -> Object.keys(obj).map((key) -> obj[key])
      @view = new StatusBarView

    it 'should create the required elements', ->
      expect(@view.children.length).toBe(3)

    it 'should set the appropriate classes', ->
      expect(Object.values(@view.classList)).toContain('tracker-status')
      expect(Object.values(@view.classList)).toContain('tracker-status')
      expect(Object.values(@view.iconSpan.classList)).toContain('icon')
      expect(Object.values(@view.iconSpan.classList)).toContain('icon-graph')
      expect(Object.values(@view.children[1].classList)).toContain('atom-tracker-name')
      expect(Object.values(@view.velocitySpan.classList)).toContain('badge')
      expect(Object.values(@view.velocitySpan.classList)).toContain('badge-small')

  describe 'updateContent method', ->
    projectData = {}
    view = null

    beforeEach ->
      @projectData =
        project:
          current_velocity: 10
          id: 123456
          name: 'Test'
        membership_summary:
          project_color: 'abcdef'
      @view = new StatusBarView
      @view.updateContent @projectData

    it 'should insert the project data', ->
      a = @view.children[1].childNodes[0]
      expect(a.href).toContain(@projectData.project.id.toString())
      expect(a.textContent).toEqual(@projectData.project.name)
      expect(@view.children[2].textContent)
        .toEqual(@projectData.project.current_velocity.toString())

    it 'should set the project color if the configuration is set', ->
      atom.config.set 'atom-tracker.colorizeStatusBar', true
      @view.updateContent @projectData
      expect(@view.children[0].style.color)
        .toEqual('rgb(171, 205, 239)')

    it 'should not set the project color if the configuration is not set', ->
      atom.config.set 'atom-tracker.colorizeStatusBar', false
      @view.updateContent @projectData
      expect(@view.children[0].style.color)
        .toEqual('')

    it 'should hide the velocity if the configuration is not set', ->
      atom.config.set 'atom-tracker.velocityStatusBar', false
      @view.updateContent @projectData
      expect(@view.children[2].hidden).toBe(true)

    it 'should not hide the velocity if the configuration is set', ->
      atom.config.set 'atom-tracker.velocityStatusBar', true
      @view.updateContent @projectData
      expect(@view.children[2].hidden).toBe(false)


  describe 'display method', ->
    view = null

    beforeEach ->
      @view = new StatusBarView

    it 'should remove hidden attribute when shown is true', ->
      @view.hidden = true
      @view.display true
      expect(@view.hidden).toBe(false)

    it 'should set the hidden attribute to true when shown is false', ->
      @view.hidden = false
      @view.display false
      expect(@view.hidden).toBe(true)
