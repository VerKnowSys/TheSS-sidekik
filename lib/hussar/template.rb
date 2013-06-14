module Hussar
  class Template
    attr_accessor :attrs
    def initialize(name, &block)
      @attrs = {}
      @attrs[:name] = name

      instance_exec(&block)
    end

    def name
      @attrs[:name]
    end

    def software_name(name)
      @attrs[:software_name] = name
    end

    def build(&block)
      @attrs[:build] = block
    end

    def start(&block)
      @attrs[:start] = block
    end

    def generate!(hooks = {}, opts = {})
      tpl = self

      addon = Addon.new(name) do
        option :env, {}
        option :git_url
        option :git_branch, "master"

        generate do
          service do
            software_name tpl.attrs[:software_name]

            configure do
              task :build_start

              chdir "$BUILD_DIR" do
                if hs = hooks[:before_build]
                  hs.each {|h| instance_exec(&h) }
                end

                instance_exec(&tpl.attrs[:build]) if tpl.attrs[:build]

                if hs = hooks[:after_build]
                  hs.each {|h| instance_exec(&h) }
                end
              end

              task :build_finish
            end

            start do
              instance_exec(&tpl.attrs[:start]) if tpl.attrs[:start]
            end
          end
        end
      end

      addon.generate!(opts)
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
