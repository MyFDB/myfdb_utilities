# encoding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'fakeweb'

FakeWeb.allow_net_connect = false
RSpec.configure do |c|
  c.mock_with :mocha
end

def fixtures_directory
  File.expand_path('../fixtures', __FILE__)
end

