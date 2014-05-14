# Status: work in progress

namespace :webapp do

set :datestamp,  Time.now.strftime("%Y-%m-%d")


# need to update status/stop/start to reflect tomcat

desc "Check tomcat status and restart if not running"
task :tomcat_check do
	on roles(:app), in: :sequence do |host|
		if test("sudo service nginx status")
			puts "status up on #{host.hostname}"
		else
			puts 'Service is not running. Attempting to restart..'
			execute "sudo service nginx stop" 
			if test("sudo service nginx start")
				puts "Service was successfully restarted"
			else
				puts "Attempt to restart failed. Aborting.."
				exit
			end
		end
	end
end


# need to update status/stop/start to reflect varnish

desc "Check varnish status and restart if not running"
task :varnish_check do
	on roles(:app), in: :sequence do |host|
		if test("sudo service nginx status")
			puts "status up on #{host.hostname}"
		else
			puts 'Service is not running. Attempting to restart..'
			execute "sudo service nginx stop" 
			if test("sudo service nginx start")
				puts "Service was successfully restarted"
			else
				puts "Attempt to restart failed. Aborting.."
				exit
			end
		end
	end
end


desc "Download Webapp war file"
task :download do
	on roles(:app), in: :sequence do |host|
	args = ['URL', 'UN', 'PW']
  args_empty?(args)
  puts 'Donwloading app..'
  warfile = get_warfile_from ENV['URL']
  if test("ls ~/#{warfile}")
   puts "warfile name: #{warfile}"
  else
   puts "Cannot find #{warfile} in home dir. Aborting.."
   exit 
  end
 end
end


 desc "Backup current release"
	task :backup do
		on roles(:app), in: :sequence do |host|
			if test("[ ! -f /var/tmp/backup/#{fetch(:datestamp)}/ROOT.war ]")
				puts 'Backing up files..'
				execute "mkdir -p /var/tmp/backup/#{fetch(:datestamp)}"
				execute "sudo mv /opt/test-apache-tomcat-7.0.42/webapps/ROOT* /var/tmp/backup/#{fetch(:datestamp)}"
				puts 'Back up successful'
			else
			  puts "Backup war file already exists for #{fetch(:datestamp)}"
			end # end-if
		end # end-roles

	end #end-taks


desc "Deploy webapp"
	task :deploy do
 		on roles(:app), in: :sequence do |host|
 			puts 'Deploying files..'
 			 execute "sudo cp ~/#{get_warfile_from ENV['URL']} /opt/test-apache-tomcat-7.0.42/webapps/ROOT.war"
 		   puts 'Deployment successful'	
 		  end
 		end



desc "Restart application"
task :restart do
	on roles(:app), in: :sequence do |host|
   puts "Restarting app servers"
   execute "sudo service nginx stop"   # dummy servers
 	 execute "sudo service nginx start"  # dummy servers
  end
end

desc "Cleanup activities"
task :cleanup do
	on roles(:app), in: :sequence do |host|
   puts "Remove downloaded war file"
   execute "rm ~/#{get_warfile_from ENV['URL']}"
  end
end


desc "Rollback to previous release"
 task :rollback do
 	on roles(:app), in: :sequence do |host|
 	 puts 'Attempting rollback..'
 	 backups = capture("ls /var/tmp/backup")
 	 previous_release = find_latest_from backups	
 	 execute "sudo cp /var/tmp/backup/#{previous_release}/ROOT*  /opt/test-apache-tomcat-7.0.42/webapps/"
 	 puts 'Rollback successful'		
 	end
 end


end # webapp end

before 'webapp:download', 'webapp:tomcat_check'
before 'webapp:deploy', 'webapp:download'
before 'webapp:deploy', 'webapp:backup'
after 'webapp:deploy', 'webapp:restart'
after 'webapp:deploy', 'webapp:cleanup'