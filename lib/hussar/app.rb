module Hussar
  class App
    attr_accessor :name, :addons, :env, :prefix, :template

    def initialize(config, debug = false)
      @name     = config.delete(:name)
      @template = config.delete(:template)
      @addons   = config.delete(:addons) || []

      @options = Options.new(config)
      @options[:service_prefix] = @name
      @options[:debug] = debug
    end

    def generate!
      puts "--> Generating new application #{@name}"

      @tpl = Template[@template]

      addons = initialize_addons
      exported_options = addons.inject({}) do |h, (a, conf)|
        a.exported_options(self, Options.new(conf)).each do |addon, opts|
          h[addon] ||= []
          h[addon] << opts
        end

        h
      end

      generated_addons = addons.map do |addon, conf|
        addon.generate!(self, conf.merge(@options), exported_options[addon.name])
      end

      hooks = generated_addons.inject(IndifferentHash.new) do |h,a|
        a[:hooks].each do |name, hook|
          h[name] ||= []
          h[name] << {
            :hook => hook,
            :options => a[:opts]
          }
        end
        h
      end

      services = generated_addons.inject({}) {|h,a| h.merge(a[:services]) }

      app_addon = @tpl.generate!(self, services.keys, hooks, @options)

      services.merge(app_addon[:services])
    end

    def opts
      @tpl.options
    end

    def initialize_addons
      @addons.map do |conf|
        [Hussar::Addon[conf.delete(:type)], conf]
      end
    end
  end
end
