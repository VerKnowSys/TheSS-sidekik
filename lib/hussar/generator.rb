module Hussar
  class Generator < Inner
    def initialize(addon, &block)
      @addon = addon
      @services = {}
      super(&block)
    end

    def service(name = nil, &block)
      name = @addon.name unless name

      if @services[name]
        raise "Service #{name} for addon #{addon.name} is already defined"
      else
        @services[name] = Service.new(name, &block).generate!(@options)
      end
    end

    def generate!(options = {})
      super
      {
        :services => @services
      }
    end
  end
end
