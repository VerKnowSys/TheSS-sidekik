addon "Postgresql" do
  generate do
    service do
      software_name "Postgresql"

      start do
        info "Launching Postgresql"
        sh %Q{
          SERVICE_ROOT/exports/pg_ctl \\
            -D SERVICE_PREFIX/database \\
            -l SERVICE_PREFIX/service.log \\
            -o "-k SERVICE_PREFIX" start
        }
      end

      configure do
        # This one needs to be guarded by 'test ! -d' to prevent remove database
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

      validate do
        check_dir "database/base"
        check_file "database/pg_hba.conf"
        check_file "database/postgresql.conf"
      end

      stop do
        sh %Q{
          SERVICE_ROOT/exports/pg_ctl \\
            --timeout=60 -w \\
            -D SERVICE_PREFIX/database stop
        }
      end

      baby_sitter do
        sh "SERVICE_ROOT/exports/pg_ctl -D SERVICE_PREFIX/database status", :nolog
        expect "server is running", 60
      end
    end
  end
end
