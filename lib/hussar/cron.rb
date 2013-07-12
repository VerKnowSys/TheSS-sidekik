module Hussar
  class Cron < Inner
    def initialize(app, service, &block)
      super(app, &block)
      @service = service
      @actions = []
    end

    def cron(conf, &block)
      @actions << Shell.new(app, @service, "cron", &block).generate!(@options).merge(
        :cronEntry => conf
      )
    end
  end
end
