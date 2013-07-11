module Hussar
  class Inner
    def initialize(app, &block)
      @app = app
      @block = block
    end

    def app
      @app
    end

    def opts
      @options
    end

    def generate!(options)
      @options = options
      instance_exec(&@block)
    end

    def service_prefix
      opts[:service_prefix] ? "#{opts[:service_prefix]}-" : ""
    end
  end
end
