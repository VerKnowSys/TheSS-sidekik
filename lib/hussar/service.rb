module Hussar
  class Service < Inner
    PHASES = {
      :install        => :shell,
      :configure      => :shell,
      :start          => :shell,
      :stop           => :shell,
      :reload         => :shell,
      :validate       => :shell,
      :baby_sitter    => :shell
    }
    FIELDS = PHASES.merge(
      :software_name  => :string,
      :watch_port     => :bool,
      :scheduler_actions => :cron,
      :dependencies   => :dependencies,
      :ports_pool     => :ports
    )

    def initialize(include_default_fields = true, &block)
      super(&block)
      @include_default_fields = include_default_fields
      @fields = {}
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
            @fields[:#{field}] = Shell.new("#{field}", &block)
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
      h = {}

      if @include_default_fields
        if di = default_install
          h[:install] = di
        end
      end

      h
    end

    def default_install
      if @fields[:software_name]
        soft = @fields[:software_name].downcase
        Shell.new("install") do
          sh "sofin get #{soft}", :novalidate
          expect "All done"
        end
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
