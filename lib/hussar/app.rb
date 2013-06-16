module Hussar
  class App
    attr_accessor :name, :addons, :env, :prefix

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

      addons = genenerate_addons(@options)

      hooks = addons.inject(IndifferentHash.new) do |h,a|
        a[:hooks].each do |name, hook|
          h[name] ||= []
          h[name] << hook
        end
        h
      end

      services = addons.inject({}) {|h,a| h.merge(a[:services]) }

      template = Template[@template]
      app_addon = template.generate!(services.keys, hooks, @options)

      services.merge(app_addon[:services])
    end

    def genenerate_addons(options = {})
      @addons.map do |conf|
        conf.merge!(@options)
        type = conf.delete(:type)
        addon = Hussar::Addon[type]
        addon.generate!(conf)
      end
    end
  end
end
