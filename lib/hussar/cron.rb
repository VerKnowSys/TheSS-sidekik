module Hussar
  class Cron < Inner
    def initialize(app, &block)
      super
      @actions = []
    end

    def cron(conf, &block)
      @actions << Shell.new(app, "cron", &block).generate!(@options).merge(
        :cronEntry => conf
      )
    end
  end
end
