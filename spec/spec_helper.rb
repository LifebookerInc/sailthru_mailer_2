require 'simplecov'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'sailthru_mailer'
require 'ruby-debug'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Bundler.require(:default, :test)
Debugger.start

SimpleCov.start do
  add_filter "/spec/"
end

SimpleCov.at_exit do
  SimpleCov.result.format!
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
end
