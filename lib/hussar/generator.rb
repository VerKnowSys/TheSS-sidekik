module Hussar
  class Generator < Inner
    def initialize(addon, &block)
      @addon = addon
      @services = {}
      @hooks = {}
      super(&block)
    end

    def service(name = nil, &block)
      name = @addon.name unless name

      if @services[name]
        raise "Service #{name} for addon #{addon.name} is already defined"
      else
        @services[name] = Service.new(&block).generate!(@options)
      end
    end

    def hooks(&block)
      @hooks = Hooks.new(&block).generate!(@options)
    end

    def generate!(options)
      puts "--> Generating igniters for addon #{@addon.name} with #{options}"

      super

      services = Hash[@services.map do |name, srv|
        ["#{options[:service_prefix]}-#{name}", srv]
      end]

      {
        :services => services,
        :hooks => @hooks
      }
    end
  end
end
