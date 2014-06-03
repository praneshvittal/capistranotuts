# Capistrano Tutorial #


Introduction to Capistrano 3. 

Note: The approach in this tutorial is from a non-deployment perspective. What this means is I am not delving into 'how to deploy' rather
nuggets of information on Capistrano features.

#### Disclaimer: #### The information captured here is to the best of my knowledge. If information is inaccurate please let me know.

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

You define the **namespace** `db`. Within the namespace we define **tasks**. In this case, we defined a single task called `status`. The task executes on servers that have been assigned the `db` role. All our databases have been assigned the `db` role so it will run the task on all databases. We could have just as easily replaced `roles(:db)` with `roles(:postgres)` to only check the status of the postgres servers.


If it's still not hitting the spot, think of **roles** as **groups**. Your servers will belong to one or more groups and **tasks** are run on these groups.



#### What's in the lib/capistrano/tasks directory?  ####

As the name implies, this is where you create your task files.


We will look at tasks in more detail next along with some other Capistrano nuggets.


## Doing Something with Capistrano ##

### Controlling Capistrano output  ###

Capistrano provides various levels of output. Usually when first writing your tasks it is a good idea to set the log level to `info` or `debug` to see verbose output of the execution flow. When you're confident it is behaving as expected you can replace the log level with `error` and use custom output.

Capistrano output types:

```ruby
   TRACE = -1
   DEBUG = 0
   INFO  = 1
   WARN  = 2
   ERROR = 3
   FATAL = 4
```

This is usually set within `config/deploy.rb`:

```ruby
# Default value for :log_level is :debug
set :log_level, :ERROR
```

By minimizing log output, you can use ruby `put` statements inside your task to give customized output.


### Using Capistrano variables  ###

You can define a regular ruby variable or do it via the capistrano DSL like so:

```ruby
# Defining the variable
set :datestamp,  Time.now.strftime("%Y-%m-%d")

# Using variable
puts "The date is: #{fetch(:datestamp)}"
```

`fetch(:variable_name)` is part of the Capistrano DSL. The rest of it is ruby [string interpolation](http://en.wikipedia.org/wiki/String_interpolation#Ruby).



###  Executing commands ###

Simply execute commands on the remote server by doing:

```ruby
execute "sudo mkdir /mnt/backup"
```


### Capturing output  ###

Use the `capture` command to get output from remote host: 

```ruby
# Returns the hostname of the server which is stored in a variable
hostname = capture 'hostname'

# Prints hostname to standard output
puts hostname
```


### Getting input from a user ###

You can also prompt users for input:

```ruby
ask :input, "Download file again? [y/n]"

# show the user input
puts "#{fetch(:input)}"
```

`ask` is a method that can take 2 arguments. One is the variable that you store the user input and the other is the text to display.


### Using Capistrano with Ruby  ###

To keep your code DRY it is a good idea to extract code into functions.

Here is an arbitary example to show you what can be done:

```ruby

# lib/capistrano/helpers.rb

def get_hostname
 capture 'hostname'
end

# lib/capistrano/tasks/file.rake

import  'lib/capistrano/helpers.rb'

desc 'check if file exists'
 task :cat_file do
  on roles(:app), in: :sequence do |host|
   puts get_hostname # calling the function in helpers.rb
   execute 'cat sample.txt'
 end
end
```



### Defining a task  ###

Tasks can loosely be broken down into 3 parts.

+ First, we give it a description and a task name so that when we run  `cap -T` it will display the task name along with a description
+ Next we specify a `role` to run the task on as discussed before
+ Lastly,  we take action by executing commands, performing some logic etc.


#### Here are some simple examples  #####


Running a task in parallel:


```ruby 
desc "Get hostname"
 task :get_hostname do
  on roles(:webapp) do |host|
   execute 'hostname'
   execute 'ls -l'
  end
 end

 ```

 The above task will first execute the hostname command on all servers first and subsequently execute the list command.


 To run a task in sequence:

```ruby 
desc "Get hostname"
 task :get_hostname do
  on roles(:webapp), in: :sequence do |host|
   execute 'hostname'
   execute 'ls -l'
  end
 end

 ```

 Now it will run the commands sequencially on each host before moving onto the next host.

Something to always remember is the native ruby blocks in use. Everytime you use `do` it needs to have an `end` to terminate the block.


### Tasks Demystified  ###


Here is a task that downloads a war file. This may seem daunting at first but I will dissect it from star to finish.

```ruby
desc "Download Webapp war file"
task :download do
	puts make_task_title_pretty "DOWNLOAD APP"
    warfile_name = get_warfile_name_from ENV['URL']

	on roles(:webapp_tomcat), in: :sequence do |host|
	# If file exists prompt user to confirm if re-download required
  if test("ls /var/tmp/#{warfile_name}")
  	puts "#{$warning} File already exists on #{get_hostname}"
  	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 puts download_warfile_from get_hostname, warfile_name
  	else
  		puts "#{$checkmark} Using existing file - Nothing to do."
  	end
  else
  	# Download since file doesn't exist
	  puts download_warfile_from get_hostname, warfile_name
	end
	puts "\n"
 end
 puts "\n"
end

```


Lets break this down.

```ruby
desc "Download Webapp war file"
task :download do
```

Here we provide a description and name the task. We also start our first `do` block which will be terminated with `end`.


```ruby
puts make_task_title_pretty "DOWNLOAD APP"
```

Now we swiching to ruby to make the title pretty. Basically calling a function `make_task_title_pretty` that will return "DOWNLOAD APP" with some formatting.

lets move on.

```ruby
warfile_name = get_warfile_name_from ENV['URL']
```

only difference here is I am using `ENV['URL']` to access the argument provided in the Capistrano command. This will be clear with an example:

```ruby
cap staging webapp:download URL='http://yamininaidu.com.au/wp/wp-content/uploads/2014/02/classic-batman-logo.jpg'
```

If it hasn't sunk in yet, `ENV['URL']` gives me access to the value of `URL` passed as an argument in the cap command. Simple right?

Just like before I call the ruby function to get the file name from the url with `get_warfile_name_from` and store it in a variable for later use.

next.

```ruby
on roles(:webapp_tomcat), in: :sequence do |host|
```

We specify which role(s) we are going to run this task on. We also want the commands to be executed sequencially on each host.


Now comes the logic and something I haven't introduced yet.

```ruby
if test("ls /var/tmp/#{warfile_name}")
  	puts "#{$warning} File already exists on #{get_hostname}"
  	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 puts download_warfile_from get_hostname, warfile_name
  	else
  		puts "#{$checkmark} Using existing file - Nothing to do."
  	end
  else
  	# Download since file doesn't exist
	  puts download_warfile_from get_hostname, warfile_name
	end
```

Capistrano by nature will terminate if a command fails for whatever reason. This is because it looks at the `exit` code and anything other than `0` is considered to be failure.

You can override this behavior with:

```ruby
# always set the return code to true
execute "ls /var/tmp/sample.txt;", raise_on_non_zero_exit: false
```

So even if `sample.txt` doesn't exist, Capistrano won't terminate with an error. However, this is risky because in most cases you either want it to terminate or do something else if it fails. This is where `if test()` triumphs.

This means you can use `if else` logic with unix commands inside `test()..`

Back to the main code block, It checks if the war file exists and prompts the user to download again otherwise just download the file.

Lets keep breaking it down:

```ruby
puts "#{$warning} File already exists on #{get_hostname}"
```

`$warning` is a ruby global variable defined with a unicode symbol for some visual appeal. As you know by now, `get_hostname` is another method.


```ruby
	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 puts download_warfile_from get_hostname, warfile_name
  	else
  		puts "#{$checkmark} Using existing file - Nothing to do."
  	end
```

we get the input with the `ask` method and check if user accept or declines.
