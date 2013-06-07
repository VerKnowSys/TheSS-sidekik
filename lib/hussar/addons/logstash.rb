addon "LogStash" do |a|
  a.software_name "Logstash"
  a.watch_port false

  a.ports_pool do
    no_ports

    port if opt[:udp]
  end

  a.option :udp, false
  a.option :redis, true
  a.option :elasticsearch, true

  a.dependencies do
    dependency "Redis" if opt[:redis]
    dependency "ElasticSearch" if opt[:elasticsearch]
  end

  a.start do
    info "Launching Logstash"

    daemonize "SERVICE_ROOT/exports/logstash agent -f SERVICE_PREFIX/service.conf"
  end

  a.validate do
    vars = []
    input = []
    output = []

    if opt[:udp]
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

    if opt[:redis]
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

    if opt[:elasticsearch]
      vars << service_domain("ElasticSearch")
      vars << current_user
      output << %Q|
        elasticsearch {
          host    => "%s"
          cluster => "%s"
        }
      |
    end


    file "service.conf", vars, <<-EOS
      input {
        #{input.join("\n")}
      }

      output {
        #{output.join("\n")}
      }

    EOS
  end
end
