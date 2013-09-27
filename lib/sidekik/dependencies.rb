module Sidekik
  class Dependencies < Inner
    def initialize(app, &block)
      super
      @dependencies = []
    end

    def generate!(*args)
      super
      @dependencies.map do |name, with_prefix|
        with_prefix ? "#{service_prefix}#{name}" : name
      end
    end

    def dependency(name, with_prefix = true)
      @dependencies << [name, with_prefix]
    end
  end
end
