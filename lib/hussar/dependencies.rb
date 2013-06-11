module Hussar
  class Dependencies < Inner
    def initialize(&block)
      super
      @dependencies = []
    end

    def generate!(*args)
      super
      @dependencies.map {|e| "#{service_prefix}#{e}"}
    end

    def dependency(name)
      @dependencies << name
    end
  end
end
