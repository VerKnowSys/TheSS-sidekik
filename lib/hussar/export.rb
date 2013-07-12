module Hussar
  class Export
    def initialize(addon, &block)
      @addon = addon
      @block = block
      @exported_options = {}
    end

    def opts
      @options
    end

    def generate!(app, options)
      @app = app
      @options = options
      instance_exec(&@block)
      @exported_options
    end

    def export_option(name, &block)
      @exported_options[name] = block
    end

    def service_prefix(service_name = nil)
      service_name ||= @addon.name
      service_name = "#{@app.name}-#{service_name}"
      prefix = opts[:service_prefix] ? "#{opts[:service_prefix]}-" : ""
      "SERVICE_PREFIX/../#{prefix}#{service_name}"
    end
  end
end
