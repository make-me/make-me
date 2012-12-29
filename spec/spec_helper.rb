require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
require File.expand_path('./server/app.rb')

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def app
  MakeMe::App
end
