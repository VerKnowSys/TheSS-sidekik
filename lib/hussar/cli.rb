require "sickle"

module Hussar
  class CLI
    include Sickle::Runner

    desc "List available addons"
    def list
      Hussar::Addon.all.each do |name, addon|
        puts "#{name.ljust(10)}"
        addon.default_options.each do |opt, default|
          puts "  - #{opt} (default: #{default})"
        end
        puts
      end
    end

    desc "Generate igniters for app"
    def gen(file)
      Hussar.make_me_cookie(file)
    end
  end
end
