# Status: work in progress

namespace :webapp do

set :datestamp,  Time.now.strftime("%Y-%m-%d")


 desc "Backup current release"
	task :backup_current do
		on roles(:app) do |host|
			if test("[ -d /var/tmp/backup ]")
				info "'backup' folder exists. Creating dir to store current release."
				execute "mkdir -p /var/tmp/backup/#{fetch(:datestamp)}"
				execute "sudo mv /opt/test-apache-tomcat-7.0.42/webapps/ROOT* /var/tmp/backup/#{fetch(:datestamp)}"
			else
			  puts 'backup folder doesn\'t exist'	
			end # end-if
		end # end-roles

	end #end-taks


end #end-webapp_deploy