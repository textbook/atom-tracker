https = require 'https'

module.exports =

  getProjectDetails: (project, success, failure) ->
    # Get the details for the specified project
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'
      path: "/services/v5/projects/#{project.project_id}?fields=:default,current_velocity"
    @makeGetRequest options, "Failed to fetch #{project.project_name} data.",
      ((data) -> success data or {}), failure

  getProjects: (success, failure) ->
    # Get all projects for the current user
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'
      path: '/services/v5/me'
    @makeGetRequest options, 'Failed to fetch project list.',
      ((data) -> success data.projects or []), failure

  makeGetRequest: (options, errMessage, success, failure) ->
    req = https.get options, (res) ->
      if res.statusCode is 200
        data = []
        res.setEncoding 'utf8'
        res.on 'data', (chunk) -> data.push(chunk)
        res.on 'end', -> success JSON.parse(data.join '')
      else
        if res.statusCode is 403
          atom.notifications.addWarning 'Not authenticated, please double-' +
            'check your Tracker API Token in the package settings.',
            {icon: 'lock'}
        else
          atom.notifications.addError errMessage
        if failure
          failure res
