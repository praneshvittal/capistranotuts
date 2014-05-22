#TO-DO LIST:
# varnish restart needs to be implemented after deployment
# varnish check needs to be configued

namespace :webapp do


# Global variables
set :datestamp,  Time.now.strftime("%Y-%m-%d")

# unicode for status symbols
$checkmark =  "\u2714"
$cross     =  "\u2718"
$warning   =  "\u26A0"
$lines     =  "\u2630"



# Not used in deployment flow however useful for testing

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

  # check if the ENV global variable has command-line arguments
  args_empty?(args) 
 end

desc "Check varnish status and restart if not running"
task :varnish_check do
	make_task_title_pretty "VARNISH CHECK"
	on roles(:web), in: :sequence do |host|
		puts "#{$checkmark} Varnish: running on #{get_hostname}"
	end
	puts "\n"
end




desc "Check tomcat status and restart if not running"
task :tomcat_check do
	make_task_title_pretty "TOMCAT CHECK"
	on roles(:web), in: :sequence do |host|
		# 
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
	# if file exists prompt user to confirm if re-download required
  if test("ls /var/tmp/#{warfile_name}")
  	puts "#{$warning} File already exists on #{get_hostname}"
  	ask :input, "Download file again? [y/n]"
  	if 'yY'.include? fetch(:input)
 		 download_warfile_from get_hostname, warfile_name
  	else
  		puts "#{$checkmark} Using existing file - Nothing to do."
  	end
  else
  	# download since file doesn't exist
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

desc "Deploy webapp to Tomcat"
	task :deploy do
		make_task_title_pretty "DEPLOY APP"
 		on roles(:app), in: :sequence do |host|

 			# remove existing ROOT* from tomcat webapps dir
 			if test("ls /opt/tomcat/webapps/ROOT* && sudo rm -rf /opt/tomcat/webapps/ROOT*")
				puts "#{$checkmark} Removed existing war file in prepapration for deployment"
			end
 			puts "+ Deploying files on #{get_hostname}.."
 			 # copy new war file from to tomcat webapp dir and restart tomcat
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
 	 backups = capture("ls /mnt/backup") # get backup dir name
 	 previous_release = find_latest_from backups # 'latest' from backup dir is the previous release
	 
	 # remove existing ROOT* from tomcat webapps dir 
	 if test("sudo rm -rf /opt/tomcat/webapps/ROOT*")
		puts "#{$checkmark} Removed existing war file in prepapration for rollback"
		
		puts "Rolling back to: #{previous_release}.."
		
		# copy the previous release from backup dir to the tomcat webapps dir and restart tomcat
		if test("sudo cp -rp /mnt/backup/#{previous_release}/ROOT* /opt/tomcat/webapps/")
			puts "#{$checkmark} Files from #{previous_release} deployed"
 	 		restart_tomcat_on get_hostname, "+ Attempting to restart Tomcat.."
 	 		puts "#{$checkmark} Rollback successful"	
 	 	else
 	 		# if rollback to ../webapps/ dir fails exit script
 	 		puts "#{$cross} Rollback failed"
 	 		exit	
 	  end

	 else	
	 	puts "#{$cross} Unable to remove existing war file..Aborting"
	 	exit
	 end
 	 
 	 puts "\n"
 	end
 end


# use cleanup to remove any unwanted files

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


end # webapp namespace end


# webapp:deploy workflow #

before 'webapp:download', 'webapp:pre_check' 
before 'webapp:download', 'webapp:varnish_check'
before 'webapp:download', 'webapp:tomcat_check'
after  'webapp:download', 'webapp:backup' 

before 'webapp:deploy', 'webapp:download'
after 'webapp:deploy', 'webapp:cleanup'