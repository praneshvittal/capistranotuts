namespace :dev do
	
	desc "execute test script on server"
	 task :test_script do 
	 	on roles(:web) do |host|
	 	  	'/home/vagrant/test.sh'
	 end
	end

	desc "upload file"
		task :test_upload do
			on roles(:web) do |host|
				 upload!("upload-test", "/home/vagrant/")
		end
	end

end