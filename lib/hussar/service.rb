module Hussar
  class Service < Inner
    FIELDS = {
      :software_name  => :string,
      :watch_port     => :bool,
      :scheduler_actions => :cron,
      :install        => :shell,
      :configure      => :shell,
      :start          => :shell,
      :stop           => :shell,
      :reload         => :shell,
      :validate       => :shell,
      :baby_sitter    => :shell,
      :dependencies   => :dependencies,
      :ports_pool     => :ports
    }

    def initialize(name, &block)
      @name = name
      @fields = {}
      super(&block)
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

    def generate!(*args)
      super

      default_fields.merge(@fields).inject({}) do |hash, (field, gen_or_value)|
        value = if gen_or_value.respond_to?(:generate!)
          gen_or_value.generate!(@options)
        else
          gen_or_value
        end
        hash.merge(Hussar.camel_case(field) => value)
      end
    end
  end
end
