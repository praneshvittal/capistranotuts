namespace :status do

set :message, "This a test message"


task :default do
	invoke 'status:webserver'
	invoke 'status:database'
end



desc "Check status of nginx on web server"
	task :webserver do
		on roles(:web) do |host|
		  execute "echo '#{fetch(:message)}'"
			sudo 'service nginx status'
		end
	end


desc "Check status of DB"
 task :database do
 	 on roles(:db) do |host|
 		execute 'hostname'
 		execute 'service postgresql status'
 	 end
 end


end


