# -*- encoding: utf-8 -*-
require File.expand_path('../lib/frenzy_bunnies/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dotan Nahum"]
  gem.email         = ["jondotan@gmail.com"]
  gem.description   = %q{RabbitMQ JRuby based workers on top of march_hare}
  gem.summary       = %q{RabbitMQ JRuby based workers on top of march_hare}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "frenzy_bunnies"
  gem.require_paths = ["lib"]
  gem.version       = FrenzyBunnies::VERSION
  
  gem.add_dependency 'march_hare', '~> 2.8'
  gem.add_dependency 'thor'
  gem.add_dependency 'sinatra'
  gem.add_dependency 'atomic'
  gem.add_dependency 'json'
  gem.add_dependency 'thread_safe'

  gem.add_development_dependency 'guard-coffeescript'
  gem.add_development_dependency 'rspec', '~>3.0'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'ruby-debug'
end
