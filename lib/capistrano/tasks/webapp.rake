#TO-DO LIST:
# need to update status/stop/start to reflect tomcat
# need to update status/stop/start to reflect varnish
# need to update path of tomcat
# need to restart tomcat servers
# roles need to be updated

namespace :webapp do

set :datestamp,  Time.now.strftime("%Y-%m-%d")


# TO-DO: need to update status/stop/start to reflect tomcat



desc "Check tomcat status and restart if not running"
task :tomcat_check do
	puts '== TOMCAT CHECK =='.rjust(25)
	on roles(:web), in: :sequence do |host|
		hostname = capture('hostname')
		if test("sudo service httpd status") 
			puts "/ Tomcat: running on #{hostname}"
		else
			puts "+ Service is not running on #{hostname}. Attempting to restart.."
			restart_tomcat_on hostname
		end
	end
	puts "\n"
end


# TO-DO: need to update status/stop/start to reflect varnish

desc "Check varnish status and restart if not running"
task :varnish_check do
	puts '== VARNISH CHECK =='.rjust(25)
	on roles(:web), in: :sequence do |host|
		if test("sudo service nginx status")
			hostname = capture('hostname')
			puts "Varnish: running on #{hostname}"
		else
			puts 'Service is not running. Attempting to restart..'
			execute "sudo service nginx stop" 
			if test("sudo service nginx start") != 0
				puts "Service was successfully restarted"
			else
				puts "Attempt to restart failed with non-zero exit status. Aborting.."
				exit
			end
		end
	end
	puts "\n"
end



desc "Download Webapp war file"
task :download do
	puts '== DOWNLOAD APP =='.rjust(25)
	on roles(:app), in: :sequence do |host|
	args = ['URL', 'UN', 'PW', 'TCR']
  args_empty?(args)
  warfile = get_warfile_name_from ENV['URL']
  if test("ls /var/tmp/#{warfile}")
  	puts '! File already exists'
  	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 download warfile
  	else
  		puts '/ Using existing file - Nothing to do.'
  	end
  else
	  download warfile
	end # end-test
 end
end

# TO-DO: need to update path of tomcat

 desc "Backup current release"
	task :backup do
		on roles(:app), in: :sequence do |host|
		# 	if test("[ ! -f /var/tmp/backup/#{fetch(:datestamp)}/ROOT.war ]")
		# 		puts 'Backing up files..'
		# 		execute "mkdir -p /var/tmp/backup/#{fetch(:datestamp)}"
		# 		execute "sudo mv /opt/test-apache-tomcat-7.0.42/webapps/ROOT* /var/tmp/backup/#{fetch(:datestamp)}"
		# 		puts 'Back up successful'
		# 	else
		# 	  puts "Backup war file already exists for #{fetch(:datestamp)}"
		# 	end # end-if
		# end # end-roles

		# if backup path doesn't exist, create it /mnt/backup
		# create backup directory with date_tcr
		# cp ../webapps/ROOT* to /mnt/backup/date_tcr

		end
	end #end-taks


# TO-DO: need to update path of tomcat

desc "Deploy webapp"
	task :deploy do
 		on roles(:app), in: :sequence do |host|
 			puts 'Deploying files..'
 			 execute "sudo cp ~/#{get_warfile_name_from ENV['URL']} /opt/test-apache-tomcat-7.0.42/webapps/ROOT.war"
 		   puts 'Deployment successful'	
 		  end
 		end


# TO-DO: need to restart tomcat servers

desc "Restart application"
task :restart do
	on roles(:app), in: :sequence do |host|
   puts "Restarting app servers.."
   execute "sudo service nginx stop"   # dummy servers 
 	 if test("sudo service nginx start")  # dummy servers
    puts 'Application restart was successful'
   else
   	puts 'Application restart failed'
   end
  end
end

desc "Cleanup activities"
task :cleanup do
	on roles(:app), in: :sequence do |host|
   puts "Remove downloaded war file"
   execute "rm ~/#{get_warfile_name_from ENV['URL']}"
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


# webapp:deploy workflow #

before 'webapp:download', 'webapp:varnish_check'
before 'webapp:download', 'webapp:tomcat_check'


before 'webapp:deploy', 'webapp:download'
before 'webapp:deploy', 'webapp:backup'
after 'webapp:deploy', 'webapp:restart'
after 'webapp:deploy', 'webapp:cleanup'