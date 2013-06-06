addon "LogStash" do |a|
  a.software_name "Logstash"
  a.watch_port false

  a.option :upd, false
  a.option :redis, true
  a.option :elasticsearch, true

  a.start do
    info "Launching Logstash"

    daemonize "SERVICE_ROOT/exports/logstash agent -f SERVICE_PREFIX/config.conf"
  end

  a.validate do
    vars = []
    input = []
    output = []

    if opt[:udp]
      vars << read_var(".domain")
      vars << read_var(".ports")
      input << %Q|
        udp {
          host => "%s"
          port => %s
          type => "udp"
        }
      |
    end

    if opt[:redis]
      vars << read_var(".domain", "Redis")
      vars << read_var(".ports", "Redis")
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
      vars << read_var(".domain", "ElasticSearch")
      vars << "USER"
      input << %Q|
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
