namespace :nginx do
desc "Check status of web server"

    task :nginx_status do
      on roles(:web) do |host|
        execute 'hostname' 
        execute 'service nginx status'
      end
    end
end



