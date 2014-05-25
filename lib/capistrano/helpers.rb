require 'uri'

def args_empty? args
	count = 0
	args.each do |key|
		# check if the ENV arguments exist
		if ENV[key].nil?
			puts "#{$warning} Missing argument: #{key}"
			count = count + 1
		else
			# check if the ENV values are empty
			if ENV[key].empty?
				count = count + 1
			end
		end
	end
 if count > 0
 	puts "Run like cap staging task-name-space:task-name URL=path-to-file UN=username PW=password TCR=TCR#"
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
	   puts "#{$checkmark} Downloaded #{warfile_name} on #{hostname}"
	 else
	   puts "#{$cross} Cannot find #{warfile_name} in home dir. Aborting.."
	   exit 
	 end
end



def restart_tomcat_on hostname, message
  puts message 

  # stop/start tomcat as owner

	execute "sudo /etc/init.d/tomcat stop"
	execute "sudo /etc/init.d/tomcat start"

	if tomcat_status.include? 'pid'
		puts "#{$checkmark} Tomcat: running on #{hostname}"
	else
		puts "#{$cross} Restart failed on #{hostname}. Aborting.."
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

	execute "sudo /etc/init.d/varnish restart"

	if varnish_status.include? 'pid'
		puts "#{$checkmark} Varnish: running on #{hostname}"
	else
		puts "#{$cross} Restart failed. Please re-start Varnish manually on #{hostname}"
	end
end


def varnish_status 
	capture "sudo /etc/init.d/varnish status"
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

def make_task_title_pretty task_name
	puts "#{$lines} #{$lines}   #{task_name}   #{$lines} #{$lines}"
end



def find_latest_from backups
	dates = backups.split("\n")
	return dates.max
end





