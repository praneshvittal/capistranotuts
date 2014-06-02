require 'uri'

def args_empty? args
	count = 0
	args.each do |key|
		# Check if the ENV arguments exist
		if ENV[key].nil?
			"#{$warning} Missing argument: #{key}"
			count = count + 1
		else
			# Check if the ENV values are empty
			if ENV[key].empty?
				count = count + 1
			end
		end
	end
 if count > 0
 	"Run like cap staging task-name-space:task-name URL=path-to-file UN=username PW=password TCR=TCR#"
 	exit
 end
end


def get_warfile_name_from url
	uri = URI.parse(url)
	File.basename(uri.path)
end


def download_warfile_from hostname, warfile_name
	puts '+ Downloading app..(May take a while depending on the file size)'
	execute "wget --user=#{ENV['UN']} --password=#{ENV['PW']} #{ENV['URL']} -O /var/tmp/#{warfile_name}"
	if test("ls /var/tmp/#{warfile_name}")
	   "#{$checkmark} Downloaded #{warfile_name} on #{hostname}"
	 else
	   "#{$cross} Cannot find #{warfile_name} in home dir. Aborting.."
	   exit 
	 end
end



def restart_tomcat_on hostname, message
  puts message 

  # stop/start tomcat as owner

	execute "sudo /etc/init.d/tomcat stop"
	execute "sudo /etc/init.d/tomcat start"

	if tomcat_status.include? 'pid'
		"#{$checkmark} Tomcat: running on #{hostname}"
	else
		"#{$cross} Restart failed on #{hostname}. Aborting.."
		exit
	end
end


def tomcat_status
	# capture "ps x | grep /opt/tomcat/ | grep -v grep | awk '{print $1}'" 
	capture "sudo /etc/init.d/tomcat status"
end


# use this script if tomcat takes a while to start inside restart_tomcat_on
def is_tomcat_running?
	count = 2 
	while count != 30 do
		
		if ! tomcat_status.empty?
			return 'yes'
		else
			puts 'Waiting another 2 secs..(Will terminate in 60 secs)'
			sleep(2)
			count = count + 2
		end
	end
	return 'no'
end


def restart_varnish_on hostname, message
  puts message 

  # stop/start tomcat as owner

	execute "sudo /etc/init.d/varnish stop"
	execute "sudo /etc/init.d/varnish start"

	if varnish_status.include? 'pid'
		"#{$checkmark} Varnish: running on #{hostname}"
	else
		"#{$cross} Restart failed. Please re-start Varnish manually on #{hostname}"
	end
end


def varnish_status 
	# when you check the status of varnish, it returns error code 3 when it is stopped. 
	# turning off error exit code to make capture pass.
	capture "sudo /etc/init.d/varnish status", raise_on_non_zero_exit: false 
end


def display error
puts 'MESSAGE:'
puts error
puts 'END'
puts "\n"
end


def get_hostname
	capture('hostname')
end

def get_version_info_from path, search_string
	  			
	# chck if file exists
	if test("ls #{path}")
		# get build info
		if test("grep 'Build-Time' #{path}")
			"+ Deployment info: \n #{$checkmark} #{capture "grep #{search_string} #{path}"}" 
		else
		  "#{$warning} Cannot retrieve deployment info: \n#{$cross} Unable to find \'#{search_string}\' in #{path}"
		end		
	else
		  "#{$warning} Cannot retrieve deployment info: \n#{$cross} Unable to find file: #{path}"
	end
end





def make_task_title_pretty task_name
	"#{$lines} #{$lines}   #{task_name}   #{$lines} #{$lines}"
end






def find_latest_from backups
	dates = backups.split("\n")
	return dates.max
end





