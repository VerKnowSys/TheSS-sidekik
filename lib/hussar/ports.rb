module Hussar
  class Ports < Inner
    def reset
      @ports = 1
    end

    def generate(options = {})
      super
      @ports
    end

    def port
      ports(1)
    end

    def ports(n)
      @ports += n
    end

    def no_ports
      @ports = 0
    end
  end
end
