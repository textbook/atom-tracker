https = require 'https'

module.exports =

  getProjects: (success, failure) ->
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'
      path: '/services/v5/me'
    @makeGetRequest options, 'Failed to fetch project data.',
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
        failure res
