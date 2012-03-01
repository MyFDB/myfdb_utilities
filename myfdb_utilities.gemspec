# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'version'

Gem::Specification.new do |s|
  s.name        = "myfdb_utilities"
  s.version     = Myfdb::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Larry Sprock']
  s.email       = ['development@myfdb.com']
  s.homepage    = "http://rubygems.org/gems/myfdb_utilities"
  s.summary     = "Utilities gem for myfdb"
  s.description = "A collection of purpose built utilities for doing tasks specific to MyFDB"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "rspec", ["~> 2.6.0"]
  s.add_development_dependency "mocha", ["~> 0.9"]
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "rake"
  
  s.add_dependency 'multipart-post'
  s.add_dependency 'commander'
  s.add_dependency 'cronedit'

  s.files        = `git ls-files`.split("\n")
  s.executables  = 'myfdb'
  s.require_path = 'lib'
end
