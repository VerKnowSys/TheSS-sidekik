module Hussar
  class Options < IndifferentHash
    include Hashie::Extensions::MethodQuery
    include Hashie::Extensions::MethodReader
  end

  class Addon
    attr_accessor :name, :generator
    def initialize(name, &block)
      @name = name
      @exports = {}

      instance_exec(&block)
    end

    def default_options
      @default_options ||= Options.new(:debug => false)
    end

    def option(name, default = false)
      default_options[name] = default
    end

    def export_options_for(other_addon_name, &block)
      @exports[other_addon_name] = Export.new(self, &block)
    end

    def exported_options(app, conf)
      @exports.map do |name, export|
        [name, export.generate!(app, conf)]
      end
    end

    def generate(&block)
      @block = block
    end

    def generate!(app, opts, exported_opts = [])
      gen = Generator.new(app, self, &@block)

      o = default_options.merge(opts)
      # puts
      # puts @name
      # puts o.inspect
      # puts exported_opts.inspect

      (exported_opts || []).each do |hash|
        hash.each do |opt_name, block|
          # puts "Applying #{opt_name}"
          # o[opt_name]
          # puts "before: #{o[opt_name]}"
          o[opt_name] = block.call(o[opt_name])
          # puts "after: #{o[opt_name]}"
        end
      end


      # puts o.inspect
      # puts

      data = gen.generate!(o)
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
        all[name] || (raise "Addon #{name} not found!")
      end
    end
  end
end
