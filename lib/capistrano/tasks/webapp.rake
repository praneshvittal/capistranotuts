#TO-DO LIST:
# need to update status/stop/start to reflect tomcat
# need to update status/stop/start to reflect varnish
# need to update path of tomcat
# need to restart tomcat servers
# roles need to be updated

namespace :webapp do


# Global variables
set :datestamp,  Time.now.strftime("%Y-%m-%d")
$checkmark =  "\u2714"
$cross     =  "\u2718"
$warning   =  "\u26A0"
$lines     =  "\u2630"


desc "Test ssh connection"
  task :test_connection do
  	on roles(:web), in: :sequence do |host|
  		hostname =capture "hostname"
  		puts hostname
  	end
	end



desc "Checks if command line arguments are present before running webapp:download"
 task :pre_check do
 	args = ['URL', 'UN', 'PW', 'TCR']
  args_empty?(args)
 end


desc "Check varnish status and restart if not running"
task :varnish_check do
	make_task_title_pretty "VARNISH CHECK"
	on roles(:web), in: :sequence do |host|
		puts "#{$checkmark} Varnish: running on #{get_hostname}"
	# 	else
	# 	if test("sudo service httpd status") 
	# 		puts "#{$checkmark} Varnish: running on #{get_hostname}"
	# 	else
	# 		restart_varnish_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
	# 	end
	end
	puts "\n"
end




# TO-DO: need to update status/stop/start to reflect tomcat

desc "Check tomcat status and restart if not running"
task :tomcat_check do
	make_task_title_pretty "TOMCAT CHECK"
	on roles(:web), in: :sequence do |host|
		if tomcat_status.include? 'pid'
		#if !tomcat_status.empty?
			puts "#{$checkmark} Tomcat: running on #{get_hostname}"
		else
			restart_tomcat_on get_hostname, "+ Service is not running on #{get_hostname}. Attempting to restart.."
		end
	end
	puts "\n"
end




desc "Download Webapp war file"
task :download do
	make_task_title_pretty "DOWNLOAD APP"
  warfile_name = get_warfile_name_from ENV['URL']

	on roles(:app), in: :sequence do |host|
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



 desc "Backup current release (dependant on webapp:download)"
	task :backup do
		make_task_title_pretty "BACKUP CURRENT RELEASE"
		on roles(:app), in: :sequence do |host|

		puts "+ Starting backup process on #{get_hostname}.."

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
	end #end-task


# TO-DO: need to update path of tomcat

desc "Deploy webapp"
	task :deploy do
		make_task_title_pretty "DEPLOY APP"
 		on roles(:app), in: :sequence do |host|
 			if test("ls /opt/tomcat/webapps/ROOT* && sudo rm -rf /opt/tomcat/webapps/ROOT*")
				puts "#{$checkmark} Removed existing war file in prepapration for deployment"
			end
 			puts "+ Deploying files on #{get_hostname}.."
 			 if test("cp /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/tomcat/webapps/ROOT.war")	
 		  	restart_tomcat_on get_hostname, "+ Attempting to restart Tomcat.."
 		  	puts "#{$checkmark} Deployment successful"
 		 	else
 		 		error = capture "cp /var/tmp/#{get_warfile_name_from ENV['URL']} /opt/tomcat/webapps/ROOT.war"
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
  make_task_title_pretty "ROLLBACK"
 	on roles(:app), in: :sequence do |host|
 	 puts "+ Attempting rollback on #{get_hostname}.."
 	 backups = capture("ls /mnt/backup")
 	 previous_release = find_latest_from backups
	 if test("sudo rm -rf /opt/tomcat/webapps/ROOT*")
		puts "#{$checkmark} Removed existing war file in prepapration for rollback"
		if test("sudo cp -rp /mnt/backup/#{previous_release}/ROOT* /opt/tomcat/webapps/")
			puts "#{$checkmark} Files from backup deployed"
 	 		restart_tomcat_on get_hostname, "+ Attempting to restart Tomcat.."
 	 		puts "#{$checkmark} Rollback successful"	
 	  end
	 else
	 	puts "#{$cross} Unable to remove existing war file..Aborting"
	 	exit
	 end
	 # copy files from /mnt/backup /opt/tomcat/webapps/ while retaining permissions
 	 
 	 puts "\n"
 	end
 end



 desc "Cleanup activities (dependant on webapp:download)"
task :cleanup do
	make_task_title_pretty "CLEAN UP"
	on roles(:app), in: :sequence do |host|
   puts "+ Removing downloaded files.."
   if test("sudo rm /var/tmp/#{get_warfile_name_from ENV['URL']}")
   	puts "#{$checkmark} #{get_warfile_name_from ENV['URL']} removed"
   else
   	error = capture "sudo rm /var/tmp/#{get_warfile_name_from ENV['URL']}"
   	display error
   	puts "#{$warning} Unable to remove file. Please perform this action manually."
   end
  end
end


end # webapp end


# webapp:deploy workflow #

before 'webapp:download', 'webapp:pre_check' 
before 'webapp:download', 'webapp:varnish_check'
before 'webapp:download', 'webapp:tomcat_check'
after  'webapp:download', 'webapp:backup' 

before 'webapp:deploy', 'webapp:download'
before 'webapp:deploy', 'webapp:backup'
# after 'webapp:deploy', 'webapp:cleanup'