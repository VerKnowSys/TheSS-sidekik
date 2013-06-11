module Hussar
  class Cron < Inner
    def initialize(&block)
      super
      @actions = []
    end

    def cron(conf, &block)
      @actions << Shell.new(&block).generate!(@options).merge(
        :cronEntry => conf
      )
    end
  end
end
