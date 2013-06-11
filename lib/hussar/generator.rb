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
        @services[name] = Service.new(&block).generate!(@options)
      end
    end

    def app(&block)
      @app = Service.new(false, &block).generate!(@options)
    end

    def generate!(*args)
      super
      {
        :services => @services,
        :app => @app
      }
    end
  end
end
