require 'net/http/post/multipart'
require 'heroku'

# remove these in favor of a yaml file
UPLOAD_USERNAME = 'upload'
UPLOAD_PASSWORD = '33919dcb0f764d016f16d06d720c36b6a18b6260'

module MyfdbUtilities
  module IssuesUploader
    extend self
  
    def upload(args)
      error_report = []
    
      heroku(args['user'], args['password'])
      app_name(args['host'].to_s.split(".")[0])
      working_directory = "/Users/Shared/magazines/#{app_name}"
    
      if File.exists? working_directory
        Dir.glob("#{working_directory}/*") do |issue_directory|
          id_file = File.join issue_directory, 'issue_id'
        
          issue_id = if File.exists? id_file
            File.read id_file
          else
            begin
              uri = URI.parse "http://#{UPLOAD_USERNAME}:#{UPLOAD_PASSWORD}@#{args['host']}/upload/issues"
              response = Net::HTTP.post_form(uri, {})
              if response.code == '200'
                _issue_id = response.body
                File.open(File.join(issue_directory, 'issue_id'), 'w') do |file|
                  file.puts _issue_id
                end
                _issue_id
              else
                error_report << "Unknown response, body: #{response.body}, code: #{response.code}"
                next
              end
            rescue => error
              error_report << "Error creating issue, error: #{error.class}, message: #{error.message}"
              next
            end
          end
          
          join_images(issue_directory)
          
          images = Dir.glob(File.join(issue_directory, '*.{jpeg,JPEG,jpg,JPG}'))
        
          if !images.empty?
            set_workers args['workers_start'] || 3 if worker_count <= 1
          
            images.each do |image|
              begin
                uri       = URI.parse "http://#{args['host']}/upload/tear_sheets"
                upload_io = UploadIO.new image, 'image/jpeg'
                multipart = Net::HTTP::Post::Multipart.new(uri.path, 'issue_id' => issue_id, 'tear_sheet[image]' => upload_io)
              
                response  = Net::HTTP.start(uri.host, uri.port) do |http|
                  multipart.basic_auth UPLOAD_USERNAME, UPLOAD_PASSWORD
                  http.request multipart
                end
              
                if response.code == '200'
                  FileUtils.rm_rf image
                elsif response.code == '422'
                  error_report << "Invalid image, response: #{response.body}"
                else
                  error_report << "Unknown response, issue: #{issue_id.chomp}, image: #{image}, response: #{response.body}, code: #{response.code}"
                end
            
              rescue => error
                error_report << "Error creating tear sheet '#{image}', error: #{error.class}, message: #{error.message}"
              end
            end
          
            sleep 60
            set_workers args['workers_finished'] || 1
          end
        end
      else
        raise StandardError, "#{working_directory} does not exist. Please create this directory and continue."
      end
    
      error_report.join("\n")
    end
  
    def set_workers(count)
      current = heroku.set_workers(app_name, count)
      puts "#{app_name} now running #{current} workers"
    end
  
    def worker_count
      info = heroku.info(app_name)
      info[:workers].to_i
    end
  
    def app_name(name=nil)
      return @app unless name
      @app = name
    end
  
    def heroku(user=nil, password=nil)
      @heroku ||= Heroku::Client.new(user, password)
    end
    
    def join_images(path, image_groups={})
      image_files = Dir.glob(File.join(path, '*-[a-z]-[0-9].{jpeg,JPEG,jpg,JPG}'))
      
      if !image_files.empty?
        keys = image_files.collect { |img|  File.basename(img) =~ /-([a-z])-[0-9]/ ; $1}.uniq
        keys.each { |key| image_groups[key] = [] }

        image_files.each do |image|
          File.basename(image) =~ /-([a-z])-([0-9])/
          image_groups[$1] << image
        end

        image_groups.each_value do |images|
          strip_extension_regex = /-[a-z]-[0-9].(?i)JPE?G/
          escaped_image_paths   = images.collect { |image_path| image_path.gsub(/ /, '\ ') }
          joined_image_path     = escaped_image_paths.first.gsub(strip_extension_regex, '') + '-joined' + '.jpg'

          %x(convert #{escaped_image_paths.join(' ')} +append #{joined_image_path})
          
          images.each do |image|
            joined_image_name = File.basename(joined_image_path.gsub(/.(?i)JPE?G/, ''))
            File.open(File.join(path, File.basename(image).gsub(strip_extension_regex, '')) + "-merged_with-#{joined_image_name}", 'w') do |file|
              file.puts "Merged into #{joined_image_name}.jpg"
            end 
            FileUtils.rm_rf image
          end
        end
      end
    end
  
  end
end