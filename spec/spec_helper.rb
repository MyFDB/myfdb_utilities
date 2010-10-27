$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'
Bundler.setup

require 'spec'
require 'fakeweb'
require 'myfdb_utilities'


FakeWeb.allow_net_connect = false

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
