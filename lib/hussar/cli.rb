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
    option :prefix, :default => nil
    option :output_dir, :default => nil
    def gen(file)
      Hussar.make_me_cookie(file, options)
    end
  end
end
