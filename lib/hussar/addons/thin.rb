addon "Thin" do
  option :workers, 1

  # export_options "Nginx" do
  #   upstream = (0...opts.workers).map {|e| [:unix, "#{service_prefix}/service.#{i}.sock"] }
  #   export_option :upstream, upstream
  # end

  generate do
    service do
      software_name "Ruby"
      watch_port false

      ports_pool do
        no_ports
      end

      install do
        sh "sofin get ruby", :novalidate
        sh "test -f SERVICE_ROOT/exports/thin || (gem install thin && sofin export thin ruby)", :novalidate
      end

      bin = lambda do |command|
        sh %Q{
          SERVICE_ROOT/exports/thin \\
            --daemonize \\
            --rackup #{make_path "current/config.ru", app_name} \\
            --servers #{opts.workers} \\
            --socket SERVICE_PREFIX/thin.sock \\
            --pid SERVICE_PREFIX/thin.pid \\
            --log SERVICE_PREFIX/thin.log \\
            #{command}
        }
      end


      workers = (0...opts.workers)

      baby_sitter do
        pidfiles = workers.map {|i| "SERVICE_PREFIX/thin.#{i}.pid" }
        check_pids pidfiles
        expect_timeout 60
      end

      start do
        run bin, "start"
      end

      stop do
        run bin, "stop"
      end
    end
  end
end
