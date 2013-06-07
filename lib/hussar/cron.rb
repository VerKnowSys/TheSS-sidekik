module Hussar
  class Cron < Inner
    def reset
      @actions = []
    end

    def cron(conf, &block)
      @actions << Shell.new(&block).generate(opt).merge(
        :cronEntry => conf
      )
    end
  end
end
