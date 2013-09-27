module Sidekik
  class IndifferentHash < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end

  def self.to_json(hash)
    hash = hash.to_hash unless hash.is_a?(Hash)
    JSON.pretty_generate(hash).gsub("\\n", "\n")
  end

  def self.camel_case(str)
    str.to_s.split('_').inject([]){ |a,e|
      a << (a.empty? ? e : e.capitalize)
    }.join
  end

  def self.strip_margin(str)
    return str if str =~ /\A\s*\Z/
    lines = skip_blank(skip_blank(str.split("\n").reverse).reverse)
    margin = lines.first[/^\s*/].size
    lines.map {|line| line.sub(/^\s{#{margin}}/, '') }.join("\n").chomp
  end

  def self.skip_blank(lines)
    lines.drop_while {|e| e =~ /^\s*$/ }
  end

  def self.make_me_cookie(config_file, options = {})
    config = IndifferentHash.new(JSON.load(File.read(config_file)))

    app = App.new(config, options.delete(:debug))
    services = app.generate!

    dir = options[:output_dir] || app.name
    FileUtils.mkdir_p(dir)

    services.each do |name, data|
      file = File.join(dir, "#{name}.json")
      puts "--> Saving #{name} igniter to #{file}"
      File.open(file, "w") {|f|
        f.puts Sidekik.to_json(data)
      }
    end
  end

  module DSL
    def addon(*args, &block)
      Addon.register(Addon.new(*args, &block))
    end

    def template(*args, &block)
      Template.register(Template.new(*args, &block))
    end
  end
end
