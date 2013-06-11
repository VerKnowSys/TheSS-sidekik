module Hussar
  class Inner
    def initialize(&block)
      @block = block
    end

    def opts
      @options
    end

    def generate!(opts = {})
      @options = opts
      instance_exec(&@block)
    end

    def service_prefix
      opts[:service_prefix] ? "#{opts[:service_prefix]}-" : ""
    end
  end
end
