require 'uri'

def args_empty? args
	count = 0
	args.each do |key|
		if ENV[key].nil?
			puts "Missing argument: #{key}"
			count = count + 1
		else
			if ENV[key] == ''
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


def download warfile
	 puts 'Downloading app..(May take a while depending on the file size)'
	capture "cd /var/tmp && wget --user=#{ENV['UN']} --password=#{ENV['PW']} #{ENV['URL']} -O /var/tmp/#{warfile}"
	if test("ls /var/tmp/#{warfile}")
	   puts "Dowloaded #{warfile} successfuly"
	 else
	   puts "Cannot find #{warfile} in home dir. Aborting.."
	   exit 
	 end
end



def restart_tomcat_on hostname 
	execute "sudo service httpd stop" 
	if test("sudo service httpd start")
		puts "/ Tomcat: running on  #{hostname}"
	else
		# showing failure
		error = capture "sudo service httpd start", raise_on_non_zero_exit: false # setting exit to false to stop script from terminating
		puts error
		puts "- Restart failed on #{hostname} with non-zero exit status. Aborting.."
		exit
	end
end




def find_latest_from backups
	dates = backups.split("\n")
	return dates.max
end


