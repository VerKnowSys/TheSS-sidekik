module Hussar
  class Generator < Inner
    def initialize(app, addon, &block)
      super(app, &block)
      @addon = addon
      @services = {}
      @hooks = {}
    end

    def service(name = nil, &block)
      name = @addon.name unless name

      if @services[name]
        raise "Service #{name} for addon #{addon.name} is already defined"
      else
        @services[name] = Service.new(app, &block).generate!(@options)
      end
    end

    def hooks(&block)
      @hooks = Hooks.new(app, &block).generate!(@options)
    end

    def generate!(options)
      puts "--> Generating igniters for addon #{@addon.name} with #{options}"

      super

      svcs = if options[:service_prefix]
        Hash[@services.map do |name, srv|
          ["#{options[:service_prefix]}-#{name}", srv]
        end]
      else
        @services
      end

      {
        :services => svcs,
        :hooks => @hooks,
        :opts => opts
      }
    end
  end
end
