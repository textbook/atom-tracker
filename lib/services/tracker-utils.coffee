https = require 'https'

module.exports =

  AUTH_FAIL_MSG: 'Not authenticated, please double-check your Tracker API ' +
    'Token in the package settings'
  CONNECT_FAIL_MSG: 'Failed to connect to Pivotal Tracker'

  defaultOptions: ->
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'

  getProjectDetails: (membershipSummary, success, failure) ->
    # Get the details for the specified project
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{membershipSummary.project_id}?fields=:default,current_velocity"
    @makeGetRequest options, "Failed to fetch #{membershipSummary.project_name} data",
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
    @makeGetRequest options, "Failed to fetch story list for \"#{project.name}\"",
      success, failure

  getStartedStories: (project, success, failure) ->
    # Get all stories that are started
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{project.id}/stories?with_state=started"
    @makeGetRequest options, "Failed to fetch story list for \"#{project.name}\"",
      success, failure

  createStory: (projectId, story, success) ->
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{projectId}/stories"
    @makePostRequest options, story, "Failed to create story \"#{story.name}\"",
      success

  startStory: (story) ->
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{story.project_id}/stories/#{story.id}"
    @makePutRequest options, {current_state: 'started'},
      "Failed to start story \"#{story.name}\".",
      (-> atom.notifications.addSuccess "Started story \"#{story.name}\"")

  finishStory: (story) ->
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{story.project_id}/stories/#{story.id}"
    @makePutRequest options, {current_state: 'finished'},
      "Failed to finish story \"#{story.name}\".",
      (-> atom.notifications.addSuccess "Finished story \"#{story.name}\"")

  makePostRequest: (options, data, errMessage, success, failure) ->
    postData = JSON.stringify data
    options.headers['Content-Type'] = 'application/json'
    options.headers['Content-Length'] = Buffer.byteLength postData
    options.method = 'POST'
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
        failure?(res)
    req.on 'error', (err) =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      failure?(err)
    req.setTimeout 2500, =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      req.abort()
    req.write postData
    req.end()

  makePutRequest: (options, data, errMessage, success, failure) ->
    options.headers['Content-Type'] = 'application/json'
    options.method = 'PUT'
    req = https.request options, (res) =>
      res.on('data', (data) -> console.log data)
      if res.statusCode is 200
        success?(res)
      else
        if res.statusCode is 403
          atom.notifications.addError @AUTH_FAIL_MSG, {icon: 'lock'}
        else
          atom.notifications.addError errMessage
        failure?(res)
    req.on('error', (err) =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      failure?(err)
    )
    req.setTimeout(2500, =>
      atom.notifications.addError @CONNECT_FAIL_MSG,
        {icon: 'radio-tower'}
      req.abort()
    )
    req.write JSON.stringify data
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
    req.on 'error', (err) =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      failure?(err)
    req.setTimeout 2500, =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      req.abort()
    req.end()
