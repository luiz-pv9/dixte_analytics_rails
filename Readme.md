### Event analytics - Ruby on Rails

This project is being rewritten in Golang in the following repository: [https://github.com/luiz-pv9/dixte-analytics]

--------

This project was originally intended to be more of a proof of concept rather than a final product. The goal was to implement event analytics similar to existing services such as Mixpanel, Localytics, Heap Analytics and EventHub.

#### Main Technologies

* *MongoDB* - Unstructured data storge for events and profiles
* *Ruby on Rails* - Web framework
* *Redis* - Queue for event and profile tracking requests
* *Sidekiq* - Handles Redis integration and worker spawning
* *Mongoid and Moped* - MongoDB ORM and driver for Ruby

#### Project structure

This project follows the default rails directory structure with a few exceptions:

* app/models

Not all files in the app/models directory represent a collection (or table) in the database. Since performance was a concern from the beginning, most database CRUD happens with Moped (MongoDB driver) rather than Mongoid (ORM).

* app/workers

Workers run in another process than the http server. They poll redis for pending jobs registered in queues. The workers are handled by Sidekiq.

* app/finders

The finders are used by the reports to provide "raw" data about events, profiles and properties.

* app/reports

Reports are what pretty much matters after events are registed. They provide useful information about how the users are using an application. All reports respond with JSON format that the pages should render.

#### Reports

Currently, the implemented reports are:

* Trending report

Given a time range, finds the most common events users are performing in the app.

* Segmentation report

Given a time range, event type and property name, segments the values of that property. Accept filters for the event.
It's also possible to view the segmentation by total count, unique by user and average by user.

* Funel report

Given a time range and steps of events, shows where in the steps the users stop executing the next action. It is possible to view details about the funnel, such as number of profiles in a given step, average time from the previous step and segment the funnel by a property in any step.

* Common actions report

Given a time range and two events, shows the most common actions users do between those events.