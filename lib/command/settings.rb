class Settings
  attr_reader :key, :secret, :host

  def initialize
    @key, @secret, @host = parse_settings
  end

  def directory
    File.join home_directory, 'MyFDB_Uploads'
  end

  def file
    "#{ENV['HOME']}/.myfdb"
  end

  def parse_settings
    File.read(file).split('|')
  end
  
  def home_directory
    running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
  end

  def running_on_windows?
    RUBY_PLATFORM =~ /mswin32|mingw32/
  end
end
