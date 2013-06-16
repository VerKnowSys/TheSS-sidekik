addon "Redis" do
  option :activerehashing, true

  generate do
    service do
      software_name "Redis"

      start do
        info "Launching Redis"
        sh "SERVICE_ROOT/exports/redis-server SERVICE_PREFIX/service.conf"
      end

      configure do
        service_mkdir "database"
        service_file "service.conf", service_port do
          <<-EOS
          # Default Redis service configuration
          # bind SERVICE_DOMAIN
          bind SERVICE_ADDRESS
          port %s
          pidfile SERVICE_PREFIX/service.pid
          dir SERVICE_PREFIX/database
          dbfilename database.rdf
          daemonize yes
          rdbcompression yes
          save 900 1
          save 300 10
          save 60 10000
          appendonly no
          appendfsync everysec
          activerehashing #{opts.activerehashing? ? 'yes' : 'no'}
          loglevel notice
          logfile SERVICE_PREFIX/service.log
          EOS
        end
      end

      validate do
        check_service_dir "database"
        check_service_file "service.conf"
      end

      scheduler_actions do
        cron "*/5 * * * * ?" do
          backup_service_file "database/database.rdf"
        end

        cron "*/2 * * * * ?" do
          service_touch "database/database.test"
        end
      end
    end
  end
end
