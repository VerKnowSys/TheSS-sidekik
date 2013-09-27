# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekik/version'


Gem::Specification.new do |spec|
  spec.name          = "sidekik"
  spec.version       = Sidekik::VERSION
  spec.authors       = ["Tymon Tobolski", "Daniel Dettlaff"]
  spec.email         = ["dmilith@verknowsys.com"]
  spec.description   = %q{Sidekik!}
  spec.summary       = %q{Sidekik!}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `find . -f -name '*.rb'`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "hashie"
  spec.add_dependency "sickle", "~> 0.5.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
