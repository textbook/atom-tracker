module.exports = config =
  trackerToken:
    default: ''
    description: 'Your access token for the Tracker API. Find it online at ' +
      'https://www.pivotaltracker.com/profile#api.'
    order: 1
    title: 'Tracker API Token'
    type: 'string'
  showStatusBar:
    default: true
    description: 'Show Atom Tracker status in the status bar.'
    order: 2
    title: 'Show Status Bar'
    type: 'boolean'
  colorizeStatusBar:
    default: false
    description: 'Use the project color in the status bar.'
    order: 3
    title: 'Colorize Status Bar'
    type: 'boolean'
  velocityStatusBar:
    default: false
    description: 'Show the project\'s current velocity in the status bar.'
    order: 4
    title: 'Show Velocity in Status Bar'
    type: 'boolean'
  showFeatureEstimate:
    default: true
    description: 'Show features\' estimated points when selecting a story.'
    order: 5
    title: 'Show Estimates in Story Selector'
    type: 'boolean'
  showStoryDetails:
    default: true
    description: 'When starting a story, show a pop-up containing its description.'
    order: 6
    title: 'Show Started Story Description'
    type: 'boolean'
  projectConfigFile:
    default: '.tracker.cson'
    description: 'This file will store the project-specific configuration, ' +
      'e.g. project Tracker ID, in your root project directory.'
    order: 7
    title: 'Project Configuration File Name'
    type: 'string'
