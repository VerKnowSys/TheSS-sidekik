addon "Mongodb" do
  generate do
    service do
      software_name "Mongodb"

      start do
        info "Launching Mongodb"
        sh "SERVICE_ROOT/exports/mongod -f SERVICE_PREFIX/service.conf"
      end

      validate do
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
    end
  end
end
