https = require 'https'

module.exports =

  AUTH_FAIL_MSG: 'Not authenticated, please double-check your Tracker API Token in the package settings.'

  defaultOptions: ->
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'

  getProjectDetails: (membershipSummary, success, failure) ->
    # Get the details for the specified project
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{membershipSummary.project_id}?fields=:default,current_velocity"
    @makeGetRequest options, "Failed to fetch #{membershipSummary.project_name} data.",
      success, failure

  getProjects: (success, failure) ->
    # Get all projects for the current user
    options = @defaultOptions()
    options.path = '/services/v5/me'
    @makeGetRequest options, 'Failed to fetch project list.',
      ((data) -> success data.projects or []), failure

  getUnstartedStories: (project, success, failure) ->
    # Get all stories that aren't started
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{project.id}/stories?with_state=unstarted"
    @makeGetRequest options, "Failed to fetch story list for \"#{project.name}\".",
      success, failure

  getStartedStories: (project, success, failure) ->
    # Get all stories that are started
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{project.id}/stories?with_state=started"
    @makeGetRequest options, "Failed to fetch story list for \"#{project.name}\".",
      success, failure

  startStory: (story) ->
    options = @defaultOptions()
    options.headers['Content-Type'] = 'application/json'
    options.method = 'PUT'
    options.path = "/services/v5/projects/#{story.project_id}/stories/#{story.id}"
    req = https.request options, (res) =>
      if res.statusCode is 200
        atom.notifications.addSuccess "Started story \"#{story.name}\"."
      else if res.statusCode is 403
        atom.notifications.addError @AUTH_FAIL_MSG, {icon: 'lock'}
      else
        atom.notifications.addError "Failed to start story \"#{story.name}\"."
    req.on('error', (err) ->
      atom.notifications.addError "Failed to connect to Pivotal Tracker.",
        {icon: 'radio-tower'}
      failure?(err)
    )
    req.setTimeout(1000, ->
      atom.notifications.addError "Failed to connect to Pivotal Tracker.",
        {icon: 'radio-tower'}
      req.abort()
    )
    req.write(JSON.stringify {current_state: 'started'})
    req.end()

  makeGetRequest: (options, errMessage, success, failure) ->
    options.method = 'GET'
    req = https.request options, (res) =>
      if res.statusCode is 200 and success
        data = []
        res.setEncoding 'utf8'
        res.on 'data', (chunk) -> data.push(chunk)
        res.on 'end', -> success JSON.parse(data.join '')
      else if res.statusCode isnt 200
        if res.statusCode is 403
          atom.notifications.addError @AUTH_FAIL_MSG, {icon: 'lock'}
        else
          atom.notifications.addError errMessage
        failure res if failure
    req.on('error', (err) ->
      atom.notifications.addError "Failed to connect to Pivotal Tracker.",
        {icon: 'radio-tower'}
      failure?(err)
    )
    req.setTimeout(1000, ->
      atom.notifications.addError "Failed to connect to Pivotal Tracker.",
        {icon: 'radio-tower'}
      req.abort()
    )
    req.end()
