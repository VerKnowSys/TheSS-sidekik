addon "Thin" do
  option :workers, 1

  export_options_for "Nginx" do
    export_option :locations do |locations|
      locations << {
        :path     => "/",
        :upstream => (0...opts.workers).map {|i|
          "unix:#{service_prefix}/thin.#{i}.sock"
        }
      }
    end
  end

  generate do
    service do
      software_name "Ruby"
      watch_port false

      ports_pool do
        no_ports
      end

      bin = lambda do |command|
        chdir app_current do
          sh %Q{
            #{app_current}/bin/thin \\
              --daemonize \\
              --rackup #{make_path "current/config.ru", app_name} \\
              --servers #{opts.workers} \\
              --socket SERVICE_PREFIX/thin.sock \\
              --pid SERVICE_PREFIX/thin.pid \\
              --log SERVICE_PREFIX/thin.log \\
              #{command}
          }
        end
      end

      baby_sitter do
        pidfiles = (0...opts.workers).map {|i| "SERVICE_PREFIX/thin.#{i}.pid" }
        check_pids pidfiles
        expect_timeout 60
      end

      start do
        env_load
        run bin, "start"
      end

      stop do
        run bin, "stop"
        sh %Q{for i in `find SERVICE_PREFIX -name "thin.*.pid"`; do svddw `cat $i`; done}
      end

    end

    hooks do
      after :build do
        info "Checking for thin binary"
        sh %Q{if [ ! -f $BUILD_DIR/bin/thin ]; then }, :novalidate
          fatal "Missing thin executable. Add gem 'thin' to Gemfile"
        sh "fi", :novalidate
      end
    end
  end
end
