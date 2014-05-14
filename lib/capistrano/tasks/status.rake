namespace :status do

set :message, "This a test message"


task :default do
	invoke 'status:webserver'
	invoke 'status:database'
end



desc "Check status of nginx on web server"
	task :webserver do
		on roles(:web) do |host|
		  execute "echo #{fetch(:message)}"
			
		  # Handling bash return codes in Capistrano 
		  # by default the task will terminate on any status code other than 0
		  # do the following to stop this behaviour:
			# execute "sudo service nginx status;", raise_on_non_zero_exit: false
			# or do this:
			if test("sudo service nginx status")	
  			puts 'nginx is running'
  			invoke 'dev:hello'  # calling a task from a different namespace
  		else
  			puts 'nginx is not running'
		  end
		end
	end


desc "Check status of DB"
 task :database do
 	 on roles(:db) do |host|
 		execute 'hostname'
 		execute 'service postgresql status'
 	 end
 end


end


