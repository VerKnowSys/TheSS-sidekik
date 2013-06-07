addon "Nginx" do |a|
  a.software_name "Nginx"


  bin = "SERVICE_ROOT/exports/nginx -c SERVICE_PREFIX/service.conf"

  a.start do
    info "Launching Nginx"
    sh "#{bin} && printf 'Nginx started\n'"
  end

  a.validate do
    file "service.conf", <<-EOS
      worker_processes 2;
      events {
          worker_connections 1024;
      }

      http {
          include SERVICE_ROOT/conf/mime.types;
          default_type application/octet-stream;
          sendfile on;
          keepalive_timeout 270;
          error_log SERVICE_PREFIX/service.log;
          server {
              listen SERVICE_ADDRESS:SERVICE_PORT;
              server_name SERVICE_DOMAIN SERVICE_ADDRESS;
              location / {
                  root SERVICE_PREFIX/html;
                  index index.html index.htm;
              }
          }
      }
    EOS

    sh "#{bin} -t && printf 'Ngins started\n'"
  end

  a.reload do
    info "Reloading Nginx"
    sh "#{bin} -s reload printf 'Nginx reloaded successfully\n'"
  end

  a.stop do
    sh "#{bin} -s stop && printf 'Nginx started\n'"
  end

  a.scheduler_actions do
    cron "0 0/30 * * * ?" do
      sh "#{bin} -t && #{bin} -s reload"
    end
  end

  a.baby_sitter do
    sh "#{bin} -t"
    expect "test is successful", 60
  end
end
