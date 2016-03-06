https = require 'https'
marked = require 'marked'
{$} = require('atom-space-pen-views')

module.exports =

  AUTH_FAIL_MSG: 'Not authenticated, please double-check your Tracker API ' +
    'Token in the package settings'
  CONNECT_FAIL_MSG: 'Failed to connect to Pivotal Tracker'
  DETAIL_SELECTOR: '.info.has-detail > .content > .detail.item > .detail-content'
  TIMEOUT: 2500

  showStoryInfo: (event, story) ->
    message = atom.notifications.addInfo "<strong>#{event}</strong>: #{story.name}",
      detail: 'replace me'
      dismissable: true
      icon: @appropriateIcon story.story_type
    el = $(@DETAIL_SELECTOR)
    el.empty().append $(marked (story.description or '*No description.*'))

  defaultOptions: ->
    options =
      headers: {'X-TrackerToken': atom.config.get 'atom-tracker.trackerToken'}
      host: 'www.pivotaltracker.com'

  appropriateIcon: (storyType) ->
    successIcon = 'star'
    if storyType is 'bug'
      successIcon = 'bug'
    else if storyType is 'chore'
      successIcon = 'gear'
    return successIcon

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
    @updateStory story, {current_state: 'started'},
      "Failed to start story \"#{story.name}\".",
      "Started story \"#{story.name}\""

  finishStory: (story) ->
    finishState = 'finished'
    if story.story_type is 'chore'
      finishState = 'accepted'
    @updateStory story, {current_state: finishState},
      "Failed to finish story \"#{story.name}\".",
      "Finished story \"#{story.name}\""

  updateStory: (story, new_state, errorMsg, successMsg) ->
    options = @defaultOptions()
    options.path = "/services/v5/projects/#{story.project_id}/stories/#{story.id}"
    @makePutRequest options, new_state, errorMsg, ->
      atom.notifications.addSuccess successMsg

  makePostRequest: (options, data, errMessage, success, failure) ->
    options.method = 'POST'
    postData = JSON.stringify data
    options.headers['Content-Type'] = 'application/json'
    options.headers['Content-Length'] = Buffer.byteLength postData
    @makeRequest options, postData, errMessage, success, failure

  makePutRequest: (options, data, errMessage, success, failure) ->
    options.method = 'PUT'
    postData = JSON.stringify data
    options.headers['Content-Type'] = 'application/json'
    @makeRequest options, postData, errMessage, success, failure

  makeGetRequest: (options, errMessage, success, failure) ->
    options.method = 'GET'
    @makeRequest options, null, errMessage, success, failure

  makeRequest: (options, postData, errMessage, success, failure) ->
    req = https.request options, (res) =>
      if res.statusCode is 200 and success
        data = []
        res.setEncoding 'utf8'
        res.on 'data', (chunk) -> data.push(chunk)
        res.on 'end', ->
          if data.length > 0
            success? JSON.parse(data.join '')
          else
            success?()
      else if res.statusCode isnt 200
        if res.statusCode is 403
          atom.notifications.addError @AUTH_FAIL_MSG, {icon: 'lock'}
        else
          atom.notifications.addError errMessage
        failure? res
    req.on 'error', (err) =>
      atom.notifications.addError @CONNECT_FAIL_MSG,
        {icon: 'radio-tower', detail: err.message}
      failure? err
    req.setTimeout @TIMEOUT, =>
      atom.notifications.addError @CONNECT_FAIL_MSG, {icon: 'radio-tower'}
      req.abort()
    if postData
      req.write postData
    req.end()
