addon "ElasticSearch" do
  option :tire, true

  generate do
    service do
      software_name "Elasticsearch"

      start do
        info "Launching ElastcSearch"
        sh %Q{
          SERVICE_ROOT/exports/elasticsearch \\
            -p SERVICE_PREFIX/service.pid \\
            -f -Xmx1g \\
            -Des.network.host=SERVICE_ADDRESS \\
            -Des.http.port=#{service_port} \\
            -Des.index.storage.type=niofs \\
            -Des.max-open-files=true \\
            -Des.bootstrap.mlockall=true \\
            -Des.cluster.name=$USER \\
            -Des.path.home=SERVICE_PREFIX
        }, :background
      end

      configure do
        copy_from_software_root "config"
        service_mkdir "data"
        service_mkdir "work"
        service_mkdir "logs"
        set_env "ELASTICSEARCH_URL", "http://SERVICE_ADDRESS:#{service_port}"
      end

      validate do
        check_service_dir "config"
        check_service_dir "data"
        check_service_dir "work"
        check_service_dir "logs"
      end
    end

    if opts.tire?
      hooks do
        before :build do
          info "Generating Tire configuration for Elasticsearch"
          file "$BUILD_DIR/config/initializers/tire_dynamic_es_port.rb" do
            <<-EOS
            Tire.configure { url ENV["ELASTICSEARCH_URL"] } if ENV["ELASTICSEARCH_URL"]
            EOS
          end
        end
      end
    end
  end
end
