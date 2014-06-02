#TO-DO LIST:
# varnish restart needs to be implemented after deployment
# varnish check needs to be configued
# updates roles to match model, prod etc.

import 'lib/capistrano/helpers.rb'

namespace :webapp do


# Global variables
set :datestamp,  Time.now.strftime("%Y-%m-%d")

# Unicode for status symbols
$checkmark =  "\u2713"
$cross     =  "\u02Df"
$warning   =  "\u26A0"
$lines     =  "\u2630"

# Not used in deployment flow however useful for testing
desc "Test ssh connection"
  task :test_connection do
  	on roles(:webapp_tomcat), in: :sequence do |host|
  		hostname = capture "hostname"
  		puts hostname
			puts get_version_info_from "/opt/tomcat/webapps/ROOT/META-INF/MANIFEST.MF", 'Build-Time'
  	end
	end

desc "Checks if command line arguments are present before running webapp:download"
 task :pre_check do
 	args = ['URL', 'UN', 'PW', 'TCR']

  # Check if the ENV global variable has command-line arguments URL,UN etc.
  puts args_empty?(args) 
 end

desc "Check varnish status and restart if not running"
task :varnish_check do
	puts make_task_title_pretty "VARNISH CHECK"
	on roles(:varnish_cache_webapp), in: :sequence do |host|
		execute "hostname" 	
		if varnish_status.include? 'pid'
			puts "#{$checkmark} Varnish: running on #{get_hostname}"
		else
			puts restart_varnish_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
		end
	end
	puts "\n"
end

# Restart all varnish servers once app is deployed
desc "Restart webapp varnish servers"
	task :varnish_restart do
		puts make_task_title_pretty "VARNISH RESTART"
		on roles(:varnish_cache_webapp), in: :sequence do |host|
			puts restart_varnish_on get_hostname, "+ Attempting to restart Varnish.."
		end
		puts "\n"
	end 


desc "Check tomcat status and restart if not running"
task :tomcat_check do
	puts make_task_title_pretty "TOMCAT CHECK"
	on roles(:webapp_tomcat), in: :sequence do |host|
		# The tomcat_status function returns the result of service tomcat status.
		# If tomcat is running 'running with pid..' is returned
		if tomcat_status.include? 'pid'
			puts "#{$checkmark} Tomcat: running on #{get_hostname}"
		else
			# Attempt to restart tomcat if not running
			puts restart_tomcat_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
		end
	end
	puts "\n"
end


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

 desc "prints the environment variables"
	task :print_env do
		on roles(:webapp_tomcat), in: :sequence do |host|
			puts "ENV['TCR'] is #{ENV['TCR']}"
			puts "time stamp is #{fetch(:datestamp)}"
		end
 	end
	



 desc "Backup current release (dependant on webapp:download)"
	task :backup do
		puts make_task_title_pretty "BACKUP CURRENT RELEASE"
		on roles(:webapp_tomcat), in: :sequence do |host|

		puts "+ Starting backup process on #{get_hostname}.."

		# If backup path doesn't exist, create it: /mnt/backup
		if test("[ ! -d /mnt/backup ]")
			puts "+ Creating backup point /mnt/backup"
			execute "sudo mkdir /mnt/backup"
			puts "#{$checkmark} Created /mnt/backup"
		end

		# Create backup directory with date_tcr#
		if test("[ ! -d /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']} ]")
			puts "+ Creating backup dir /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}"
			execute "sudo mkdir /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}"
		end

		# Copy current release to backup folder
		puts "+ Backing up files.."
		if test( "sudo cp -rfp /opt/tomcat/webapps/ROOT* /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}")
			puts "#{$checkmark} Backup successful"
		else
			error = capture "sudo cp -rfp /opt/tomcat/webapps/ROOT* /mnt/backup/#{fetch(:datestamp)}_#{ENV['TCR']}"
			display error
			puts "#{$cross} Backup failed..Aborting"
			exit
		end
		puts "\n"
	 end
	 puts "\n"
	end 


desc "Deploy webapp to Tomcat"
	task :deploy do
		puts make_task_title_pretty "DEPLOY APP"
 		on roles(:webapp_tomcat), in: :sequence do |host|

 			# Remove existing ROOT* from tomcat webapps dir
 			if test("ls /opt/tomcat/webapps/ROOT* && sudo rm -rf /opt/tomcat/webapps/ROOT*")
				puts "#{$checkmark} Removed existing war file in prepapration for deployment"
			end
 			puts "+ Deploying files on #{get_hostname}.."
 			 # Copy new war file from /var/tmp to tomcat webapp dir and restart tomcat
 			 if test("sudo cp /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/tomcat/webapps/ROOT.war")	
 			 	puts "#{$checkmark} files deployed" 
 		  	puts restart_tomcat_on get_hostname, "+ Attempting to restart Tomcat.."
 		  	puts "#{$checkmark} Deployment successful"
 		  	puts get_version_info_from "/opt/tomcat/webapps/ROOT/META-INF/MANIFEST.MF", 'Build-Time'
 		 	else
 		 		error = capture " sudo cp /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/tomcat/webapps/ROOT.war"
				display error
				puts "#{$cross} Deployment failed..Aborting"
				exit
			end
			puts "\n"
 		 end
 		 puts "\n"
 		end


desc "Rollback to previous release"
 task :rollback do
  puts make_task_title_pretty "ROLLBACK"
 	on roles(:webapp_tomcat), in: :sequence do |host|
 	 puts "+ Attempting rollback on #{get_hostname}.."
 	 
 	 # Get backup dir name
 	 backups = capture("ls /mnt/backup | awk '{print $1}'") 
 	 
 	 # 'latest' from backup dir is the previous release
 	 previous_release = find_latest_from backups 
	 
	 # Remove existing ROOT* from tomcat webapps dir 
	 if test("sudo rm -rf /opt/tomcat/webapps/ROOT*")
		puts "#{$checkmark} Removed existing war file in prepapration for rollback"
		
		puts "+ Rolling back to: #{previous_release}.."
		
		# Copy the previous release from backup dir to the tomcat webapps dir and restart tomcat
		if test("sudo cp -rp /mnt/backup/#{previous_release}/ROOT* /opt/tomcat/webapps/")
			puts "#{$checkmark} Files from #{previous_release} deployed"
 	 		puts restart_tomcat_on get_hostname, "+ Attempting to restart Tomcat.."
 	 		puts "#{$checkmark} Rollback successful"
 	 		puts get_version_info_from "/opt/tomcat/webapps/ROOT/META-INF/MANIFEST.MF", 'Build-Time'
 	 	else
 	 		# If rollback to tomcat webapp dir fails exit script
 	 		puts "#{$cross} Rollback failed"
 	 		exit	
 	  end
	 else
	  # If removing ROOT* files from the tomcat webapp dir fails..exit	
	 	puts "#{$cross} Unable to remove existing war file..Aborting"
	 	exit
	 end
 	 
 	 puts "\n"
 	end
 end

# Cleanup taks for any house keeping activities
 desc "Cleanup activities (dependant on webapp:download)"
task :cleanup do
	puts make_task_title_pretty "CLEAN UP"
	puts "+ Removing downloaded files.."
	on roles(:webapp_tomcat), in: :sequence do |host|
   if test("sudo rm /var/tmp/#{get_warfile_name_from ENV['URL']}")
   	puts "#{$checkmark} #{get_warfile_name_from ENV['URL']} removed on #{get_hostname} "
   else
   	error = capture "sudo rm /var/tmp/#{get_warfile_name_from ENV['URL']}"
   	display error
   	puts "#{$warning} Unable to remove file on #{get_hostname}. Please perform this action manually."
   end
  end
end

end # webapp namespace end

# webapp:deploy workflow #

before 'webapp:download', 'webapp:pre_check' 
before 'webapp:download', 'webapp:varnish_check'
before 'webapp:download', 'webapp:tomcat_check'
after  'webapp:download', 'webapp:backup' 
before 'webapp:deploy'  , 'webapp:download'
after  'webapp:deploy'  , 'webapp:varnish_restart' 
after  'webapp:deploy'  , 'webapp:cleanup'

# webapp:rollback workflow #

after 'webapp:rollback', 'webapp:varnish_restart'
