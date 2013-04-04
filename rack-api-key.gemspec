# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack-api-key/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nick Zalabak"]
  gem.email         = ["techwhizbang@gmail.com"]
  gem.description   = %q{RackApiKey is a middleware that enables simple API key authentication}
  gem.summary       = %q{RackApiKey is a middleware that enables simple API key authentication}
  gem.homepage      = "https://github.com/techwhizbang/rack-api-key"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-api-key"
  gem.require_paths = ["lib"]
  gem.version       = RackApiKey::VERSION
  gem.add_dependency %q<rack>, [">= 1.0"]
  gem.add_development_dependency %q<rake>, ["0.9.2.2"]
  gem.add_development_dependency %q<rspec>, ["~> 2.12.0"]
  gem.add_development_dependency %q<rack-test>, ["~> 0.6.2"]
end
