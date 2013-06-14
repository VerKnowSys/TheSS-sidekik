module Hussar
  class Hooks < Inner
    def initialize(&block)
      @hooks = IndifferentHash.new
      super(&block)
    end

    def before(phase, &block)
      @hooks["before_#{phase}"] = block
    end

    def after(phase, &block)
      @hooks["after_#{phase}"] = block
    end

    def generate!(*args)
      super
      @hooks
    end
  end
end
