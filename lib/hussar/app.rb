module Hussar
  class App
    attr_accessor :name, :addons, :env, :prefix

    def initialize(config)
      @name     = config.delete(:name)
      @template = config.delete(:template)
      @addons   = config.delete(:addons) || []

      @options = Options.new(config)
      @options[:service_prefix] = @name
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

      template = Template[@template]
      app_addon = template.generate!(hooks, @options)

      addons << app_addon
      services = addons.inject({}) {|h,a| h.merge(a[:services]) }

      services
    end



    def genenerate_addons(options = {})
      @addons.map do |conf|
        conf[:service_prefix] = options[:service_prefix]
        type = conf.delete(:type)
        addon = Hussar::Addon[type]
        addon.generate!(conf)
      end
    end
  end
end
