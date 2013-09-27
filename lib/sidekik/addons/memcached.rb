addon "Memcached" do
  generate do
    service do
      software_name "Memcached"

      configure do
        set_env "MEMCACHED_URL", "SERVICE_ADDRESS:#{service_port}"
      end

      start do
        info "Launching Memcached"
        sh %Q{
          SERVICE_ROOT/exports/memcached \\
            -l SERVICE_ADDRESS \\
            -p #{service_port} \\
            -P SERVICE_PREFIX/service.pid -d
        }
      end
    end
  end
end
