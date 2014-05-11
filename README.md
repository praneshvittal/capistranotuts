# Capistrano #


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

`Capfile` is the main configuration file Capistrano needs. This loaded by default. You'd rarely have the need to modify this.


#### What's config/debloy.rb?   ####

`config/deploy.rb` is the file that contains your applications's default configurations. This file is geared towards Rails applications, however it can be used to to define global settings.


#### What's in the config/deploy directory?  ####

This is where different environments are defined. You can call your environment files anything you want. When you run a Capistrano task you need to specify which environment you like to run it on such as `cap staging db:status`. `staging` will refer to your `config/deploy/staging.rb` file.

Here's an example of a `staging.rb` file:

```ruby
server '192.168.0.97', roles: %w{web app db}
```

Another method of defining roles:

```ruby
role :web, "192.168.0.10"
role :app,  "192.168.0.11"
role :db, "192.168.0.12"
```

Usually you will have multiple servers defined with different roles(I'll explain roles soon). Here's another example for clarity:

(Lets assume you have defined yours servers in your `.ssh/config` file and now you can use host names)

```ruby
server 'PRODWEB', roles: %w{web}
server 'PRODAPP', roles: %w{app}
server 'PRODDB1', roles: %w{db postgres}
server 'PRODDB2', roles: %w{db postgres}
server 'PRODDB3', roles: %w{db mysql}
server 'PRODDB4', roles: %w{db mysql}
```


#### What does a 'role' mean? ####

This might be obvious to some but I thought I'll give a brief explanation anyway.

Looking at the previous code block you'll notice how i have multiple roles assigned:

```ruby
server 'PRODDB1', roles: %w{db postgres}   # Belongs to db & postgres role
server 'PRODDB4', roles: %w{db mysql}      # Belongs to db & mysql role
```

Here on, its best explained with a Capistrano command:

`cap staging db:status`

If you were to break this command down, all its doing is running the `status` task we define in the `db` namespace (again `namespace` is something we define)

Capistrano in a way is like pseudo code, so the code block below should makes sense:

```ruby
namespace :db do 

desc "Check status of DB"
 task :status do
 	 on roles(:db) do |host|
 		#execute the command on host to get the status
 	 end # end loop
 end # end task

end # end namespace
```

You define the **namespace** `db`. Then within the namespace we define **tasks**. In this case, we defined a single task called `status`. The task executes on servers that have been assigned the `db` role. All our databases have been assigned the `db` role so it will run the task on all databases. We could have just as easily replaced `roles(:db)` with `roles(:postgres)` to only check the status of the postgres servers.


So **roles** are like **groups**. There can be one or many groups. Your servers will belong to one or many groups and **tasks** are run on these groups which in Capistrano speak we refer to as **roles**. 


We will look at tasks in more detail next. 


## Doing Something with Capistrano ##


(coming soon!)







