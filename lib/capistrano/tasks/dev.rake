namespace :dev do
	
	desc "execute test script on server"
	 task :run_script do 
	 	on roles(:web) do |host|
	 	  	'/home/vagrant/test.sh'
	 end
	end

	desc "upload a script"
		task :upload_script do
			on roles(:web) do |host|
				 upload!("/script/file/location", "/home/vagrant/")
		end
	end

	desc "print globally set variable"
		task :hello do
			puts "#{:hello}"
		end

end