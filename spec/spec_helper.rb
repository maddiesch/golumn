require 'simplecov'
SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
end

require 'pry'

require 'golumn'

NOTIFICATION_NAME = Set.new

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    Golumn::Metadata.application_name = 'GolumnTest'
    Golumn::Metadata.environment = 'test'
  end
end
