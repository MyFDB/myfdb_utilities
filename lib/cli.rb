require 'rubygems'
require 'getopt/long'
require 'myfdb_utilities'

module MyfdbUtilities
  module Cli
    
    class << self
      
      def run(command)
        self.send command
      end
      
      def upload_issues
        args = Getopt::Long.getopts(
           ["--password", "-p", Getopt::REQUIRED],
           ["--user", "-u", Getopt::REQUIRED],
           ["--host", "-h", Getopt::REQUIRED],
           ["--workers_start", "-r", Getopt::OPTIONAL],
           ["--workers_finished", "-w", Getopt::OPTIONAL]
        )
                
        if errors = MyfdbUtilities::IssuesUploader.upload(args)
          puts "#{errors}" unless errors.empty?
        end
      end
      
    end
    
  end
end