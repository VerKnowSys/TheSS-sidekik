addon "Mongodb" do
  option :mongoid, true

  generate do
    service do
      software_name "Mongodb"

      start do
        info "Launching Mongodb"
        sh "SERVICE_ROOT/exports/mongod -f SERVICE_PREFIX/service.conf"
      end

      configure do
        mkdir "database", 700
        file "service.conf", <<-EOS
          bind_ip = SERVICE_ADDRESS
          port = SERVICE_PORT
          dbpath = SERVICE_PREFIX/database
          logappend = true
          logpath = SERVICE_PREFIX/service.log
          pidfilepath = SERVICE_PREFIX/service.pid
          unixSocketPrefix = SERVICE_PREFIX
          fork = true
        EOS
      end

      validate do
        check_dir "database"
        check_file "service.conf"
      end
    end

    if opts.mongoid?
      hooks do
        before :build do
          info "Generating Mongoid configuration (mongoid.yml)"

          file :absolute, "$BUILD_DIR/config/mongoid.yml", ["$RAILS_ENV", "MONGODB_URL"], <<-EOS
            %s:
              sessions:
                default:
                  database: main
                  hosts:
                    - %s
                  options:
                    safe: true
          EOS
        end

        after :build do
          rake "mongoid:create_indexes"
        end
      end
    end
  end
end
