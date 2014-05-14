namespace :dev do
	
	desc "Execute test script on server"
	 task :run_script do 
	 	on roles(:web) do |host|
	 	  	'/home/vagrant/test.sh' 
	 end
	end

	desc "Upload test script"
		task :upload_script do
			on roles(:web) do |host|
				 upload!("/script/file/location", "/home/vagrant/")
		end
	end

	desc "Asks for name and prints it out"
		task :hello do
			ask(:user, "What is your name?")
			puts fetch(:hello) + ' ' + fetch(:user) # :hello defined in config/deploy/deploy.rb
		end

end