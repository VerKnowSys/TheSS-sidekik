module Hussar
  class Dependencies < Inner
    def reset
      @dependencies = []
    end

    def generate(options = {})
      super
      @dependencies.map {|e| "#{service_prefix}#{e}"}
    end

    def dependency(name)
      @dependencies << name
    end
  end
end
