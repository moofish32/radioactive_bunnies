require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start  do
  add_filter '/spec/'
end
require 'ruby-debug'
ENV["RAILS_ENV"] ||= "test"

Dir.glob(File.join(File.dirname(__FILE__), 'support', '*.rb')).each { |f| require f}

RSpec.configure do |config|

end
