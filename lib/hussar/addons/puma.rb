addon "Puma" do

  export_options_for "Nginx" do
    export_option :locations do |locations|
      locations << {
        :path     => "/",
        :upstream => [
          "unix:#{service_prefix}/service.sock"
        ]
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

      bin = lambda do
        chdir app_current do
          sh %Q{
            #{app_current}/bin/puma \\
              --daemon \\
              --bind unix:SERVICE_PREFIX/service.sock \\
              --pidfile SERVICE_PREFIX/service.pid \\
              #{make_path "current/config.ru", app_name} 2>&1 > SERVICE_PREFIX/service.log
          }
        end
      end

      start do
        env_load
        run bin
      end

      reload do
        # TODO: https://github.com/puma/puma#cleanup-code
        sh "kill -SIGUSR2 $(cat SERVICE_PREFIX/service.pid)"
      end

    end

    hooks do
      after :build do
        info "Checking for puma binary"
        sh %Q{if [ ! -f $BUILD_DIR/bin/puma ]; then }, :novalidate
          fatal "Missing puma executable. Add gem 'puma' to Gemfile"
        sh "fi", :novalidate
      end
    end
  end
end
