# FamNet

FamNet is a headless private social network api that can connect via a public user interface (WIP) or a private user interface. It can support multiple "families" which have "members" connected through "family members". It's been intentionally designed to allow for self-hosting and distributed use cases.

##### The Backstory
FamNet came about after seeing multiple family members uncomftable using traditional public social media networks because they didn't want to share information but also didn't want to send an email because they didn't want to bother anyone. FamNet aims to be a middle ground that allows the connectiveness that social networks leverage while being distriubted and privatized to remove the productization of users. IIRC's distributed nature and Monica (Open Sourced Personal CRM) at MonicaHQ were both major influences to the system design of this project.

###### Notice
FamNet is in open beta under Version 1; FamNet will rename on offical release under "Ohana Open Source Software" a.k.a. "Ohana" or "Ohana OSS" under [this](https://github.com/OhanaOSS) Github Organization to provide seperation from my personal Github profile. This replace will occur upon the offical beta release of the public user interface. Contribute with a name for FamNet to be renamed to or the name for the public interface projects (browser and mobile), [Open an issue!] The Public Interfaces will be developed with React and React Native.

# Inital Features!

  - Create Posts, Events (and RSVPs), Recipes with Comments and child Comment Replies.
  - Upload media with a Post, Event, Recipe, or Comment.
  - Get notification system to let you know whe someone replied to your Post, Event, Recipe, or Comment; or another family member's.
  - See a family directory that family members can self update as phone numbers, emails, addresses, and more change with the years.
  - React to a Post, Event, Recipe, or Comment with an emotive: heart, like, dislike, haha, wow, sad, angry.
  - Search for family recipes by their name, description, tags, or ingredients.
  - Invite family members not on the platform via email by a single email address or mass email invite.

You can also:
  - Manage authorization through a family configuration.
  - Manage administration with user, moderator, admin, and owner roles.

### Tech

FamNet uses a number of open source projects to work properly:

* [Ruby on Rails 5] - A web-application framework that includes everything needed to create database-backed web applications!
* [Devise_token_auth] - awesome web token and authentication gem as a branch off devise.
* [Pundit] - an awesome policy management gem to manage authorization.
* [Active Model Serializer] - a serializer for Ruby on Rails
* [Docker] - a containerization in production
* [PostgreSQL] - an awesome database

And of course FamNet itself is open source with a [public repository][famnet]
 on GitHub.

### Installation

FamNet requires [Ruby](https://www.ruby-lang.org/) v2.5+ to run.

Install the dependencies and start the server.

```sh
$ cd famnet
$ bundle install
$ rails server
```

For production environments with docker from your applicaiton server with the edge docker repo. Also, you will need to ensure that you have setup a new PostgresSQL Database. You can view the docker [repo here](https://hub.docker.com/r/lassitergregg/famnet/).

Now you will want to run:
```sh
$ docker pull lassitergregg/famnet
$ docker run -e SECRET_KEY_BASE=YOUR_SECRET_KEY_BASE -e PRODUCTION_DB_NAME=YOUR_DATA_BASE_NAME -e PRODUCTION_DB_LOGIN=YOUR_DB_ADMIN_LOGIN -e PRODUCTION_DB_PASSWORD=YOUR_DB_PASSWORD -e PRODUCTION_DB_HOST=YOUR_DB_HOST -p 3000:3000 -d famnet
```
If you're running a raw server without a webserver to direct traffic, we suggest [nginx]!

### Development

Want to contribute? Great!

FamNet uses RSpec for testing and here is how to get started. Build out following the [roadmap] docs or open an issue and make a suggestion!

Clone the repo and create a branch to work in:
```sh
$ git clone https://github.com/lassiter/FamNet.git
$ git checkout -b [issue_number]-[description]
```

Once you're done, open a pull request to `api-master`.

If you want to be an even bigger help, we need help building out the documentation and reducing the barrier of entry to non-technical people.

### Todos

 - Write MORE Tests
 - Write MORE documentation
 - Write the Roadmap (what do you want to see?) [Open an issue!]
 - Setup a build with Heroku button
 - Setup CI for Testing

License
----

GNU AFFERO GENERAL PUBLIC LICENSE VERSION 3.0


**Free Software!**

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [Open an issue!]: <https://github.com/joemccann/dillinger>
   [OhanaOSS]: <https://github.com/OhanaOSS>
   [Ruby on Rails 5]: <http://rubyonrails.org>
   [Devise_token_auth]: <https://github.com/lynndylanhurley/devise_token_auth>
   [Pundit]: <https://github.com/varvet/pundit>
   [Active Model Serializer]: <https://github.com/rails-api/active_model_serializers>
   [Docker]: <http://docker.com>
   [FamNet Edge Docker]: <https://hub.docker.com/r/lassitergregg/famnet/>
   [PostgreSQL]: <http://twitter.github.com/bootstrap/>
   [roadmap]: <https://github.com/lassiter/FamNet/wiki/Roadmap-for-FamNet>

###### Special Thanks
- Thanks to Alex Stophel, Mike Stowe, and the team at Bloc.io for supporting me as I created the MVP of this project.
- Thanks to my family for allowing me to interogate them on use cases for the software.
