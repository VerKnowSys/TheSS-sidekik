module Hussar
  class Cron
    def initialize(&block)
      @block = block
      @actions = []
    end

    def generate(options = {})
      @options = options
      instance_exec(&@block)
    end

    def cron(conf, &block)
      @actions << Shell.new(&block).generate(@options).merge(
        :cronEntry => conf
      )
    end
  end
end
