module Hussar
  class Template
    attr_accessor :attrs
    def initialize(name, &block)
      @attrs = {}
      @attrs[:name] = name
      @attrs[:options] = {}

      instance_exec(&block)
    end

    def name
      @attrs[:name]
    end

    def software_name(name)
      @attrs[:software_name] = name
    end

    def option(name, default = nil)
      @attrs[:options][name] = default
    end

    def build(&block)
      @attrs[:build] = block
    end

    def start(&block)
      @attrs[:start] = block
    end

    def generate!(app, deps, hooks, opts = {})
      tpl = self

      addon = Addon.new(name) do
        option :env, {}
        option :git_url
        option :git_branch, "master"

        tpl.attrs[:options].each do |name, default|
          option name, default
        end

        generate do
          service do
            software_name tpl.attrs[:software_name]
            watch_port false

            dependencies do
              deps.each {|d| dependency d, false }
            end

            configure do
              task :build_start

              chdir "$BUILD_DIR" do
                if hs = hooks[:before_build]
                  hs.each do |h|
                    @options.merge!(h[:options] || {})
                    instance_exec(&h[:hook])
                  end
                end

                instance_exec(&tpl.attrs[:build]) if tpl.attrs[:build]

                if hs = hooks[:after_build]
                  hs.each do |h|
                    @options.merge!(h[:options] || {})
                    instance_exec(&h[:hook])
                  end
                end
              end

              task :build_finish

              if hs = hooks[:after_build_finish]
                hs.each do |h|
                  @options.merge!(h[:options] || {})
                  instance_exec(&h[:hook])
                end
              end
            end

            start do
              instance_exec(&tpl.attrs[:start]) if tpl.attrs[:start]
            end
          end
        end
      end

      addon.generate!(app, opts)
    end

    class << self
      def register(template)
        all[template.name] = template
      end

      def all
        @all ||= {}
      end

      def [](name)
        all[name] || (raise "Template #{name} not found!")
      end
    end
  end
end
