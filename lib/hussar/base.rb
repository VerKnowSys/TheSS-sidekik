module Hussar
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
    lines = skip_blank(skip_blank(str.split("\n").reverse).reverse)
    margin = lines.first[/^\s*/].size
    lines.map {|line| line.sub(/^\s{#{margin}}/, '') }.join("\n").chomp
  end

  def self.skip_blank(lines)
    lines.drop_while {|e| e =~ /^\s*$/ }
  end

  def self.make_me_cookie(config_file)
    app = IndifferentHash.new(JSON.load(File.read(config_file)))
    name = app[:name]

    puts "--> Generating new application #{name}"
    FileUtils.mkdir_p(name)

    (app["addons"] || []).each do |conf|
      type = conf.delete(:type)
      addon = Hussar::Addon[type] || (raise "Addon #{type} not found!")
      puts "--> Generating igniter for addon #{type} with #{conf}"
      File.open(File.join(name, "#{type}.json"), "w") {|f|
        f.puts Hussar.to_json(addon.generate(conf))
      }
    end
  end

  module DSL
    def addon(name, &block)
      Addon.register Addon.new(name, &block)
    end
  end
end
