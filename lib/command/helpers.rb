module Command
  module Helpers
    def set_directory(host)
      File.join home_directory, 'Documents', host.split(".").first
    end

    def create_directory?(directory)
      unless File.exists? directory
        Dir.mkdir directory
        puts "Created directory #{directory}"
      end
    end

    def parse_options(opts, errors=[])
      errors << '-u --username USERNAME' unless opts.username || ENV['MYFDB_PROCESS_MAG_USERNAME']
      errors << '-p --password PASSWORD' unless opts.password || ENV['MYFDB_PROCESS_MAG_PASSWORD']
      errors << '--host HOSTNAME, Hostname of the server' unless opts.host
      raise errors.join(', ') unless errors.empty?
    end

    def home_directory
      running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def process_not_running?(host)
      %x(ps ux | awk '/#{host}/ && !/#{Process.ppid}/ && !/#{Process.pid}/ && !/awk/ {print $2}').empty?
    end
  end
end
