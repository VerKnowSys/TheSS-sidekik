addon "ElasticSearch" do |a|
  a.software_name "Elasticsearch"

  a.start do
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

  a.validate do
    cp_r_from_root "config"
    mkdir "data"
    mkdir "work"
    mkdir "logs"
  end
end
