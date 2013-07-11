addon "Nginx" do
  option :domain, ""
  option :workers, 2

  generate do
    service do
      software_name "Nginx"

      bin = "SERVICE_ROOT/exports/nginx -c SERVICE_PREFIX/service.conf"

      start do
        info "Launching Nginx"
        sh "#{bin} && printf 'Nginx started\n'"
      end

      configure do
        upstream = "#{app_codename}-#{Time.now.to_i}"

        service_file "service.conf", [app_domain, app_port, service_port] do
          <<-EOS
          worker_processes #{opts.workers};
          events {
              worker_connections 1024;
          }


          http {
              include SERVICE_ROOT/conf/mime.types;
              default_type application/octet-stream;
              sendfile on;
              keepalive_timeout 270;
              error_log SERVICE_PREFIX/service.log;

              upstream #{upstream} {
                server %s:%s;
              }

              server {
                  listen 0.0.0.0:%s;
                  server_name #{opts.domain} SERVICE_DOMAIN SERVICE_ADDRESS;

                  root #{app_public};
                  index index.html index.htm;

                  location / {
                      proxy_set_header  X-Real-IP  $remote_addr;
                      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header  Host $http_host;
                      proxy_redirect    off;

                      if (-f $request_filename.html) {
                        rewrite (.*) $1.html break;
                      }

                      if (!-f $request_filename) {
                          proxy_pass http://#{upstream};
                          break;
                      }
                  }
              }
          }
          EOS
        end
      end

      validate do
        sh "#{bin} -t"
        info "Nginx config OK"
      end

      reload do
        info "Reloading Nginx"
        sh "#{bin} -s reload"
        info "Nginx reloaded successfully"
      end

      stop do
        sh "#{bin} -s stop"
        info "Nginx started"
      end

      scheduler_actions do
        cron "0 0/30 * * * ?" do
          sh "#{bin} -t && #{bin} -s reload"
        end
      end

      baby_sitter do
        sh "#{bin} -t", :novalidate
        expect "test is successful", 60
      end
    end
  end
end
