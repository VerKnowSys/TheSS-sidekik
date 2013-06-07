module Hussar
  class Inner
    def initialize(&block)
      @block = block
    end

    def opt
      @options
    end

    def generate(options = {})
      reset
      @options = options
      instance_exec(&@block)
    end

    def service_prefix
      opt[:service_prefix] ? "#{opt[:service_prefix]}-" : ""
    end
  end
end
