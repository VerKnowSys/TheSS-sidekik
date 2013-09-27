addon "Nginx" do
  option :domain, ""
  option :workers, 2
  option :locations, []

  generate do
    service do
      software_name "Nginx"

      bin = "SERVICE_ROOT/exports/nginx -c SERVICE_PREFIX/service.conf"

      start do
        info "Launching Nginx"
        sh "#{bin} && printf 'Nginx started\n'"
      end

      configure do
        locations_config, upstreams_config = opts.locations.map.with_index do |location, index|
          upstream_name = "#{app_codename}-#{index}-#{Time.now.to_i}"

          upstream_config = <<-EOS
              upstream #{upstream_name} {
#{location[:upstream].map {|where| "      server #{where};" }.join("\n") }
              }
          EOS

          location_config = <<-EOS
                  location #{location[:path]} {
                      proxy_set_header  X-Real-IP  $remote_addr;
                      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header  Host $http_host;
                      proxy_redirect    off;

                      if (-f $request_filename.html) {
                        rewrite (.*) $1.html break;
                      }

                      if (!-f $request_filename) {
                          proxy_pass http://#{upstream_name};
                          break;
                      }
                  }
          EOS

          [location_config, upstream_config]
        end.transpose.map {|e| e.join("\n\n")}


        service_file "service.conf", [service_port] do
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
              access_log SERVICE_PREFIX/access.log;

#{upstreams_config}

              server {
                  listen %s;
                  server_name #{opts.domain} SERVICE_DOMAIN SERVICE_ADDRESS;

                  root #{app_public};
                  index index.html index.htm;

#{locations_config}
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
        sh "#{bin} -t" #, :novalidate
        # expect "test is successful", 60
      end
    end
  end
end
