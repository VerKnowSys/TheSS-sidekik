addon "ElasticSearch" do
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
            -Des.http.port=SERVICE_PORT \\
            -Des.index.storage.type=niofs \\
            -Des.max-open-files=true \\
            -Des.bootstrap.mlockall=true \\
            -Des.cluster.name=$USER \\
            -Des.path.home=SERVICE_PREFIX
        }, :background
      end

      configure do
        cp_r_from_root "config"
        mkdir "data"
        mkdir "work"
        mkdir "logs"
        env "ELASTICSEARCH_URL", "http://SERVICE_ADDRESS:SERVICE_PORT"
      end

      validate do
        check_dir "config"
        check_dir "data"
        check_dir "work"
        check_dir "logs"
      end
    end
  end
end
