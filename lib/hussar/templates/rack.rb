template "Rack" do
  software_name "Ruby"

  build do
    task :bundle
  end

  start do
    sh %{
      cd SERVICE_PREFIX/current

      printf 'service port = %s\n' SERVICE_PORT #{log}
      bin/rackup \\
        -p SERVICE_PORT \\
        -E $RACK_ENV \\
        -D -P SERVICE_PREFIX/service.pid
    }
  end
end
