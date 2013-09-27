require "sickle"

module Sidekik
  class CLI
    include Sickle::Runner

    desc "List available addons"
    def list
      Sidekik::Addon.all.each do |name, addon|
        puts "#{name.ljust(10)}"
        addon.default_options.each do |opt, default|
          puts "  - #{opt} (default: #{default})"
        end
        puts
      end
    end

    desc "Generate igniters for app"
    option :prefix,       :default => nil
    option :output_dir,   :default => "#{ENV["HOME"]}/Igniters/Services"
    flag :debug
    def gen(file)
      Sidekik.make_me_cookie(file, options)
    end

    desc "Generate all example igniters"
    option :prefix,       :default => nil
    option :output_dir,   :default => "#{ENV["HOME"]}/Igniters/Services"
    flag :debug
    def gen_examples
      Dir[File.join(File.expand_path("../../../examples", __FILE__), "*.json")].each do |f|
        Sidekik.make_me_cookie(f, options)
      end
    end
  end
end
