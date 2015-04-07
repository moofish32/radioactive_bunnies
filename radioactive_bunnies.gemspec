# -*- encoding: utf-8 -*-
require File.expand_path('../lib/radioactive_bunnies/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Cowgill", "Bryan Konowitz"]
  gem.email         = ["moofish32@gmail.com", "bryan@konowitz.me"]
  gem.description   = %q{RabbitMQ JRuby based workers on top of march_hare}
  gem.summary       = %q{RabbitMQ JRuby based workers on top of march_hare}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "radioactive_bunnies"
  gem.require_paths = ["lib"]
  gem.version       = RadioactiveBunnies::VERSION
  
  gem.add_dependency 'march_hare', '~> 2.9'
  gem.add_dependency 'thor'
  gem.add_dependency 'sinatra'
  gem.add_dependency 'atomic'
  gem.add_dependency 'json'
  gem.add_dependency 'thread_safe'

  gem.add_development_dependency 'gem-release'
  gem.add_development_dependency 'guard-coffeescript'
  gem.add_development_dependency 'rspec', '~>3.0'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'ruby-debug'
end
