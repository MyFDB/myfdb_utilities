class Settings
  FILE = "#{ENV['HOME']}/.myfdb"

  attr_reader :key, :secret, :host

  def initialize
    @key, @secret, @host = parse_settings
  end

  def directory
    File.join home_directory, 'MyFDB_Uploads'
  end

  def parse_settings
    File.read(Settings::FILE).split('|')
  end

  def home_directory
    running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
  end

  def running_on_windows?
    RUBY_PLATFORM =~ /mswin32|mingw32/
  end
end
