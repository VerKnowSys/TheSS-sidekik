module Hussar
  class Addon
    FIELDS = {
      :software_name  => :string,
      :watch_port     => :bool,
      :scheduler_actions => :cron,
      :install        => :shell,
      :start          => :shell,
      :validate       => :shell,
      :dependencies   => :dependencies,
      :ports_pool     => :ports
    }

    attr_accessor :name

    def initialize(name, &block)
      @name = name
      @block = block
      @default_options = IndifferentHash.new
      reset
    end

    def default_options
      @default_options
    end

    FIELDS.each do |field, type|
      case type
      when :string, :bool
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{field}(value)
            @fields[:#{field}] = value
          end
        EOS
      when :shell
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{field}(&block)
            @fields[:#{field}] = Shell.new(&block)
          end
        EOS
      when :cron
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{field}(&block)
            @fields[:#{field}] = Cron.new(&block)
          end
        EOS
      when :dependencies
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{field}(&block)
            @fields[:#{field}] = Dependencies.new(&block)
          end
        EOS
      when :ports
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{field}(&block)
            @fields[:#{field}] = Ports.new(&block)
          end
        EOS
      end
    end

    def require_port!(n = 1)
      puts "REQUIRE_PORT #{n}"
      @fields[:ports_pool] ||= 0
      @fields[:ports_pool] += n
    end

    def default_fields
      {
        :install => default_install
      }
    end

    def default_install
      soft = @fields[:software_name].downcase
      Shell.new do
        sh "sofin get #{soft}", :nolog
        expect "All done"
      end
    end

    def reset
      @fields = {}
      @block.call(self)
    end

    def generate(options = {})
      reset
      options = @default_options.merge(options)
      igniter = default_fields.merge(@fields).inject({}) do |hash, (field, gen_or_value)|
        value = if gen_or_value.respond_to?(:generate)
          gen_or_value.generate(options)
        else
          gen_or_value
        end
        hash.merge(Hussar.camel_case(field) => value)
      end

      IndifferentHash.new(igniter) # mostly for testing purposes, but it might be useful somedat
    end

    def option(name, default)
      @default_options[name] = default
    end

    class << self
      def all
        @all ||= {}
      end

      def [](name)
        a = all[name]
        a && a.dup
      end

      def register(addon)
        all[addon.name] = addon
      end
    end
  end
end
