module Hussar
  class Addon
    attr_accessor :name, :generator
    def initialize(name, &block)
      @name = name

      instance_exec(&block)
    end

    def default_options
      @default_options ||= IndifferentHash.new
    end

    def option(name, default = false)
      default_options[name] = default
    end

    def generate(&block)
      @block = block
    end

    def generate!(opts = {})
      gen = Generator.new(self, &@block)
      data = gen.generate!(default_options.merge(opts))
      IndifferentHash.new(data)
    end

    class << self
      def register(addon)
        all[addon.name] = addon
      end

      def all
        @all ||= {}
      end

      def [](name)
        all[name]
      end
    end
  end
end
