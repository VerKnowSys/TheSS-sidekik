addon "Sidekiq" do
  option :config_file
  option :queues, []
  option :require
  option :concurrency, 25

  generate do
    service do
      software_name "Ruby"
      watch_port false

      ports_pool do
        no_ports
      end

      start do
        env_load
        chdir app_current do
          cmd = []
          cmd << "#{app_current}/bin/sidekiq"
          cmd << "  --logfile SERVICE_PREFIX/service.log"
          cmd << "  --pidfile SERVICE_PREFIX/service.pid"
          cmd << "  --daemon"
          cmd << "  --concurrency #{opts.concurrency}"
          cmd << "--require #{opts.require}" if opts.require?
          opts.queues.each do |q|
            cmd << "  --queue #{q}"
          end

          sh cmd.join(" \\\n")
        end
      end

    end

    hooks do
      after :build do
        info "Checking for sidekiq binary"
        sh %Q{if [ ! -f $BUILD_DIR/bin/sidekiq ]; then }, :novalidate
          fatal "Missing sidekiq executable. Add gem 'sidekiq' to Gemfile"
        sh "fi", :novalidate
      end
    end
  end
end
