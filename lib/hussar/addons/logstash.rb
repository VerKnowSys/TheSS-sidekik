addon "LogStash" do
  option :udp, false
  option :redis, true
  option :elasticsearch, true

  generate do
    service do
      software_name "Logstash"
      watch_port false

      ports_pool do
        no_ports

        port if opts.udp?
      end


      dependencies do
        dependency "Redis" if opts.redis?
        dependency "ElasticSearch" if opts.elasticsearch?
      end

      start do
        info "Launching Logstash"

        daemonize "SERVICE_ROOT/exports/logstash agent -f SERVICE_PREFIX/service.conf"
      end

      configure do
        vars = []
        input = []
        output = []

        if opts.udp?
          vars << service_domain
          vars << service_port
          input << %Q|
            udp {
              host => "%s"
              port => %s
              type => "udp"
            }
          |
        end

        if opts.redis?
          vars << service_domain("Redis")
          vars << service_port("Redis")
          input << %Q|
            redis {
              debug   => true
              host    => "%s"
              port    => %s
              format  => "json"
              type    => "redis"
              data_type => "channel"
              key     => "logstash:channel"
            }
          |
        end

        if opts.elasticsearch?
          vars << service_domain("ElasticSearch")
          vars << current_user
          output << %Q|
            elasticsearch {
              host    => "%s"
              cluster => "%s"
            }
          |
        end


        service_file "service.conf", *vars do
          <<-EOS
          input {
            #{input.join("\n")}
          }

          output {
            #{output.join("\n")}
          }

          EOS
        end
      end

      validate do
        check_service_file "service.conf"
      end
    end
  end
end
