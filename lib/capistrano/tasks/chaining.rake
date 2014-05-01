namespace :chaining do 
 
 desc "Check status of web server"
  task :check_status do
	 	on roles(:web) do |host|
	 		# get task from status namespace defined in status.rake
	 		# run webserver task
	  	invoke 'status:webserver' 
	 end
	end
end

namespace :notifier do 

desc "print notification"
 task :print_notice do 
 		puts 'NOTIFICATION HERE'
 	end

end

# you can comma seperate to provide more tasks
after 'chaining:check_status', 'notifier:print_notice'



