# Atom Tracker

[![Build Status][3]][4]

Integrates [Pivotal Tracker][1] neatly into Atom. For more information on the
project's current status, see [its own Tracker][2] and [the CI builds][4].

## Installation and configuration

Once the package is installed, go to its settings page and enter your Tracker
API token to allow it to link to your projects. If you don't know your token,
see the guidance on where to find it in the settings.

You can then use Packages -> Atom Tracker -> Link Project to create a
`.tracker.cson` file in the current project root, which tells the package which
Tracker project to update (*note*: adding this to your `.gitignore` is
recommended).

## Start and finish stories

You can start stories in the backlog and finish started stories directly from
the editor:

![Finishing a story](https://github.com/textbook/atom-tracker/blob/master/resources/finish-story.gif?raw=true)

## Generate stories from comments

You can create chores directly from `TODO` comments in your code and bugs from
`FIXME` comments - the story ID is added to the comment, and the filename and
line number are included in the story's description:

![Creating a story](https://github.com/textbook/atom-tracker/blob/master/resources/create-todo.gif?raw=true)

[1]: https://www.pivotaltracker.com
[2]: https://www.pivotaltracker.com/n/projects/1520307
[3]: https://travis-ci.org/textbook/atom-tracker.svg?branch=master
[4]: https://travis-ci.org/textbook/atom-tracker
