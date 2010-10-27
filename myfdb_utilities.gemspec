# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'version'

Gem::Specification.new do |s|
  s.name        = "myfdb_utilities"
  s.version     = MyfdbUtilities::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Larry Sprock']
  s.email       = ['developers@myfdb.com']
  s.homepage    = "http://rubygems.org/gems/myfdb_utilities"
  s.summary     = "Internal utilities gem for myfdb"
  s.description = "At this point is just a issues uploader."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'rake'
  
  s.add_dependency 'multipart-post'
  s.add_dependency 'heroku'
  s.add_dependency 'getopt'

  s.files        = `git ls-files`.split("\n")
  s.executables  = 'myfdb'
  s.require_path = 'lib'
end