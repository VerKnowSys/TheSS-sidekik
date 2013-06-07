addon "Postgresql" do |a|
  a.software_name "Postgresql"

  a.start do
    info "Launching Postgresql"
    sh %Q{
      SERVICE_ROOT/exports/pg_ctl \\
        -D SERVICE_PREFIX/database \\
        -l SERVICE_PREFIX/service.log \\
        -o "-k SERVICE_PREFIX" start
    }
  end

  a.validate do
    sh %Q{
      test ! -d SERVICE_PREFIX/database/base && \\
        SERVICE_ROOT/exports/initdb -D SERVICE_PREFIX/database && \\
        rm -f SERVICE_PREFIX/database/pg_hba.conf && \\
        rm -f SERVICE_PREFIX/database/postgresql.conf
    }

    file "database/pg_hba.conf", <<-EOS
      # Default Postgresql service configuration
      local all all trust
      host all all 127.0.0.1/32 password
      # host all all 0.0.0.0/0 ident
      host all all 0.0.0.0/0 password
    EOS

    file "database/postgresql.conf", <<-EOS
      port = SERVICE_PORT
      max_connections = 200
      checkpoint_segments = 24
      password_encryption = on
      shared_buffers = 64MB
      temp_buffers = 32MB
      work_mem = 16MB
      max_stack_depth = 7MB
      logging_collector = true
      listen_addresses='SERVICE_DOMAIN'
    EOS
  end

  a.stop do
    sh %Q{
      SERVICE_ROOT/exports/pg_ctl \\
        --timeout=60 -w \\
        -D SERVICE_PREFIX/database stop
    }
  end

  a.baby_sitter do
    sh "SERVICE_ROOT/exports/pg_ctl -D SERVICE_PREFIX/database status"
    expect "server is running", 60
  end
end
