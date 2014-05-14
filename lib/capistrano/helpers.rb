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
 	puts "Run like cap staging task-name-space:task-name URL=path-to-file UN=username PW=password"
 	exit
 end
end


def get_warfile_from url
	uri = URI.parse(url)
	File.basename(uri.path)
end



def find_latest_from backups
	dates = backups.split("\n")
	return dates.max
end
