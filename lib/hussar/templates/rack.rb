template "Rack" do
  software_name "Ruby"

  build do
    task :bundle
  end

  # start do
  #   sh %{
  #     cd SERVICE_PREFIX/current

  #     bin/rackup \\
  #       -p #{service_port} \\
  #       -E $RACK_ENV \\
  #       -D -P SERVICE_PREFIX/service.pid
  #   }, :background
  # end
end
