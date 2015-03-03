require 'simplecov'
require 'ruby-debug'
SimpleCov.coverage_dir('target/coverage')
SimpleCov.start  do
  add_filter '/spec/'
end
ENV["RAILS_ENV"] ||= "test"

Dir.glob(File.join(File.dirname(__FILE__), 'support', '*.rb')).each { |f| require f}

RSpec.configure do |config|

end
