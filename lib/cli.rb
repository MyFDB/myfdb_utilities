require 'rubygems'
require 'getopt/long'
require 'myfdb_utilities'

module MyfdbUtilities
  module Command
    
    class << self
      
      def run(command)
        self.send command
      end
      
      def upload_issues
        args = Getopt::Long.getopts(
           ["--password", "-p", Getopt::REQUIRED],
           ["--user", "-u", Getopt::REQUIRED],
           ["--host", "-h", Getopt::REQUIRED],
           ["--ramped_workers", "-r", Getopt::REQUIRED],
           ["--return_workers", "-w", Getopt::REQUIRED]
        )
                

        if errors = MyfdbUtilities::IssuesUploader.upload(args)
          puts "#{errors}" unless errors.empty?
        end
      end
      
    end
    
  end
end