#TO-DO LIST:
# need to update status/stop/start to reflect tomcat
# need to update status/stop/start to reflect varnish
# need to update path of tomcat
# need to restart tomcat servers
# roles need to be updated

namespace :webapp do

# Global variables

set :datestamp,  Time.now.strftime("%Y-%m-%d")
$checkmark =  "\u2713"
$cross     =  "\u2718"
$warning   =  "\u26A0"

desc "Check varnish status and restart if not running"
task :varnish_check do
	puts '== VARNISH CHECK =='.rjust(25)
	on roles(:web), in: :sequence do |host|
		if test("sudo service httpd status") 
			puts "#{$checkmark} Varnish: running on #{get_hostname}"
		else
			restart_varnish_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
		end
	end
	puts "\n"
end




# TO-DO: need to update status/stop/start to reflect tomcat

desc "Check tomcat status and restart if not running"
task :tomcat_check do

	puts '== TOMCAT CHECK =='.rjust(25)
	on roles(:web), in: :sequence do |host|
		if test("sudo service httpd status") 
			puts "#{$checkmark} Tomcat: running on #{get_hostname}"
		else
			restart_tomcat_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
		end
	end
	puts "\n"
end




desc "Download Webapp war file"
task :download do
	puts '== DOWNLOAD APP =='.rjust(25)
	args = ['URL', 'UN', 'PW', 'TCR']
  args_empty?(args)
  warfile_name = get_warfile_name_from ENV['URL']

	on roles(:app, :web), in: :sequence do |host|
  if test("ls /var/tmp/#{warfile_name}")
  	puts "#{$warning} File already exists on #{get_hostname}"
  	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 download_warfile_from get_hostname, warfile_name
  	else
  		puts "#{$checkmark} Using existing file - Nothing to do."
  	end
  else
	  download_warfile_from get_hostname, warfile_name
	end # end-test
	puts "\n"
 end
 puts "\n"
end



# TO-DO: need to update path of tomcat

 desc "Backup current release"
	task :backup do
		puts '== BACKUP CURRENT =='.rjust(25)
		on roles(:app, :web), in: :sequence do |host|

		puts "Starting backup process on #{get_hostname}.."

		# if backup path doesn't exist, create it: /mnt/backup
		if test("[ ! -d /mnt/backup ]")
			puts "+ Creating backup point /mnt/backup"
			execute "sudo mkdir /mnt/backup"
			puts "#{$checkmark} Created /mnt/backup"
		end

		# create backup directory with date_tcr#
		if test("[ ! -d /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']} ]")
			puts "+ Creating backup dir /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}"
			execute "sudo mkdir /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}"
		end

		# cp current release to backup folder
		puts "+ Backing up files.."
		if test( "sudo cp /opt/test-apache-tomcat-7.0.42/webapps/ROOT* /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}/")
			puts "#{$checkmark} Backup successful"
		else
			error = capture "sudo cp /opt/test-apache-tomcat-7.0.42/webapps/ROOT* /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}/"
			display error
			puts "#{$cross} Backup failed..Aborting"
			exit
		end
		puts "\n"
	 end
	 puts "\n"
	end #end-task


# TO-DO: need to update path of tomcat

desc "Deploy webapp"
	task :deploy do
		puts '== DEPLOY APP =='.rjust(25)
 		on roles(:app, :web), in: :sequence do |host|
 			puts "Deploying files on #{get_hostname}.."
 			 if test("sudo cp /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/test-apache-tomcat-7.0.42/webapps/ROOT.war")	
 		  	puts "#{$checkmark} Deployment successful"
 		  	restart_tomcat_on get_hostname, "Attempting to restart Tomcat.."
 		 	else
 		 		error = capture "sudo mv /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/test-apache-tomcat-7.0.42/webapps/ROOT.war"
				display error
				puts "#{$cross} Backup failed..Aborting"
				exit
			end
			puts "\n"
 		 end
 		 puts "\n"
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
after  'webapp:download', 'webapp:backup' 

before 'webapp:deploy', 'webapp:download'
before 'webapp:deploy', 'webapp:backup'
# after 'webapp:deploy', 'webapp:restart'
# after 'webapp:deploy', 'webapp:cleanup'