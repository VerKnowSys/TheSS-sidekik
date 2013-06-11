addon "Mysql" do
  option :max_connections, 100

  generate do
    service do
      software_name "Mysql"
      watch_port false

      start do
        info "Launching Mysql"
        sh %Q{
          SERVICE_ROOT/exports/mysqld \\
            --defaults-file=SERVICE_PREFIX/service.conf \\
            --skip-grant-tables \\
            -C utf8
        }, :background
      end

      validate do
        mkdir "tmp", 700
        mkdir "database", 700
        file "service.conf", <<-EOS
          [mysqld_safe]
          socket = SERVICE_PREFIX/service.sock
          nice = 0

          [client]
          socket=SERVICE_PREFIX/mysql.sock

          [mysqld]
          pid-file = SERVICE_PREFIX/service.pid
          basedir = SERVICE_ROOT
          port = SERVICE_PORT
          datadir = SERVICE_PREFIX/database
          tmpdir = SERVICE_PREFIX/tmp
          language = SERVICE_ROOT/share/english
          skip-external-locking
          bind-address = SERVICE_DOMAIN
          key_buffer = 16M
          max_allowed_packet = 16M
          thread_stack = 128K
          thread_cache_size = 8
          myisam-recover = BACKUP
          max_connections = #{opts.max_connections}
          thread_concurrency = 10
          query_cache_limit = 1M
          query_cache_size = 16M
          general-log-file = SERVICE_PREFIX/service.log
          expire_logs_days = 10
          max_binlog_size = 100M
          socket = SERVICE_PREFIX/mysql.sock

          [mysqldump]
          quick
          quote-names
          max_allowed_packet = 16M

          [mysql]
          #no-auto-rehash # faster start of mysql but no tab completition

          [isamchk]
          key_buffer = 16M
        EOS
      end

      scheduler_actions do
        cron "0 */3 * * * ?" do
          sh "echo 'Mysql what? Misa nie rozumić mysql crap.'", :nolog
        end
      end
    end
  end
end
