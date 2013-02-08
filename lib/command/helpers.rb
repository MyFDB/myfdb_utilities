module Command
  module Helpers
    def settings
      @settings ||= Settings.new
    end

    def settings_file
      Settings::FILE
    end

    def main_directory
      settings.directory
    end

    def process_running?(command)
      ! %x(ps ux | awk '/#{command}/ && !/#{Process.ppid}/ && !/#{Process.pid}/ && !/awk/ {print $2}').empty?
    end
  end
end
