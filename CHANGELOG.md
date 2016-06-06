## 0.3.3 - Improve README
 * Show explicit installation instructions

## 0.3.2 - Fix issue 2
 * Don't attempt to delete a comment if the story has no description

## 0.3.1 - Add configuration option for story info
* Allow the user to choose whether or not to see the story info when starting

## 0.3.0 - Erase comment when story finished
* If a story is created from a comment, erase it when the story is finished

## 0.2.0 - Auto-start next available story
* If some stories are available, automatically start the next one

## 0.1.3 - Update package.json
* Provide correct link for bug reports

## 0.1.2 - Initial publication
* Now publicly available via http://atom.io/packages

## 0.1.1 - Show title in select lists
* Add placeholder text when selecting story/project

## 0.1.0 - Add new stories
* Add generic functionality for adding new stories
* Use relative locations for new story comments
* Support `FIXME` comments (bugs) as well as `TODO` (chores)

## 0.0.9 - Include location in TODO stories
* Include file name and line number in stories from comments
* Various bugfixes and simplifications

## 0.0.8 - Respect grammars
* When creating a TODO story, use the current grammar for comment/TODO

## 0.0.7 - Create TODO stories
* Create a new story in the icebox from a TODO comment

## 0.0.6 - Refactoring
* Split config out to a separate file
* Include warning when there isn't an active project in Atom

## 0.0.5 - Add Ability to Finish Story
* Choose a story from a drop-down list
* Only stories ready to finish (started stories) are shown
* Finish the selected story
* See a warning if no stories are ready to finish

## 0.0.4 - Add Ability to Start story
* Choose a story from a drop-down list
* Only stories ready to start (bugs/chores/estimated features) are shown
* Start the selected story
* See a warning if no stories are ready to start

## 0.0.3 - Added Velocity to Status Bar
* Shows current velocity badge
* Configurable in Settings

## 0.0.2 - Added Status Bar
* Shows project name
* Styled with project color
* Configurable in Settings

## 0.0.1 - Basic Configuration and Project Link
* Set the Tracker API token in settings
* Choose a project from the drop-down list
* Save a file (default `.tracker.cson`) containing details
