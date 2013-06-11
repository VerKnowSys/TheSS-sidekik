module Hussar
  class App
    attr_accessor :name, :addons, :env, :prefix

    def initialize(config)
      @name   = config[:name]
      @addons = config[:addons] || []
      @env    = config[:env]

      @options = Options.new
    end

    def generate!(options = {})
      addons = genenerate_addons(options)
      services = addons.inject({}) {|h,a| h.merge(a[:services]) }

      app = generate_app_service

      # Merge app phases
      addons.each do |a|
        if a[:app]
          Service::PHASES.each do |name, _|
            if a[:app][name] && a[:app][name][:commands]
              app[name] ||= {:commands => ""}
              app[name][:commands] += a[:app][name][:commands]
            end
          end
        end
      end

      services[name] = app
      services
    end

    def generate_app_service
      _env = @env # hash for ruby scopes
      configure = Shell.new do
        _env.each do |k,v|
          env k, v
        end
      end

      {
        :configure => configure.generate!(@options)
      }
    end

    def genenerate_addons(options = {})
      @addons.map do |conf|
        conf[:service_prefix] = options[:prefix]
        type = conf.delete(:type)
        addon = Hussar::Addon[type]
        puts "--> Generating igniters for addon #{type} with #{conf}"
        addon.generate!(conf)
      end
    end
  end
end
