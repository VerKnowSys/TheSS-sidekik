addon "Memcached" do
  generate do
    service do
      software_name "Memcached"

      start do
        info "Launching Memcached"
        sh %Q{
          SERVICE_ROOT/exports/memcached \\
            -l SERVICE_ADDRESS \\
            -p SERVICE_PORT \\
            -P SERVICE_PREFIX/service.pid -d
        }
      end
    end
  end
end
