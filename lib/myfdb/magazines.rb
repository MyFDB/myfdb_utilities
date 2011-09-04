require 'fileutils'
require 'myfdb/issue'

module Myfdb
  module Magazines
  
    def self.process(options)
      uri = URI.parse "http://#{options.username}:#{options.password}@#{options.host}"
      issues = []

      Dir.glob("#{options.directory}/*") do |directory|
        issue = Myfdb::Issue.new(directory, uri)
        issue.save 
        issues << issue
      end

      process_errors issues
    end

    def self.process_errors(issues)
      issues.each do |issue|
        unless issue.errors.empty?
          puts "Errors for issue ##{issue.id}:"
          issue.errors.compact.each do |error|
            puts error
          end
        end
      end
    end

  end
end
