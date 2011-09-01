require 'rubygems'
require 'core_ext/getopt/long'
require 'myfdb_utilities'

module MyfdbUtilities
  module Cli
    
    class << self
      
      def run(command)
        self.send command
      end
      
      def upload_issues
        args = Getopt::Long.getopts(
           ["--host", "-h", Getopt::REQUIRED],
        )
                
        if errors = MyfdbUtilities::IssuesUploader.upload(args)
          puts "#{errors}" unless errors.empty?
        end
      end
      
    end
    
  end
end
