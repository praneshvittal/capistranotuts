# Capistrano  #


How-To notes on Capistrano 3. 



## Setting It All Up  ##


### Installing Capistrano ###


If you're using bundler, add the following line to your Gemfile:
`gem 'capistrano', '~> 3.2.1'`

Then run:
`bundle install`

Or you can do:
`gem install capistrano`

Once Capistrano is installed, you need to setup the Capistrano project:
`cd /path/to/project`
`cap install`


### Updating capistrano ###

To update Capistrano via your Gemfile do:

`bundle update capistrano`


## Taking a Look Around  ##

### Directory structure  ###

```
.
├── Capfile
├── config
│   ├── deploy
│   │   ├── production.rb
│   │   └── staging.rb
│   └── deploy.rb
└── lib
    └── capistrano
        └── tasks
```


#### What's a Capfile?  ####

`Capfile` is the main configuration file Capistrano needs. This loaded by default.


#### What's config/debloy.rb?   ####

`config/deploy.rb` is the file that contains your Applications's default configurations. This file is geared towards Rails applications, however it can be used to to define global settings.


#### What's in the config/deploy directory?  ####

This where different environments are defined.

Here's an example of my `staging.rb` file:

`server '192.168.0.97', roles: %w{web app db}`

Another method of defining roles:

```ruby
role :web, "192.168.0.10"
role :app,  "192.168.0.11"
role :db, "192.168.0.12", primary:true
```

Usually you will have multiple servers defined with different roles. Here's another example for clarity:

Lets assume you have defined yours servers in your `.ssh/config` file and now you can you host names.

```ruby
server 'PRODWEB', roles: %w{web}
server 'PRODAPP', roles: %w{app}
server 'PRODDB1', roles: %w{db postgres}
server 'PRODDB4', roles: %w{db mysql}
```



