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

	desc "Print globally set variable"
		task :hello do
			puts "#{:hello}"
		end

end