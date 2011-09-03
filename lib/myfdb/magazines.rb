require 'net/http/post/multipart'
require 'fileutils'
require 'rmagick'

module Myfdb
  class Magazines

    attr_reader :base_directory, :issue_directories, :uri, :errors

    def initialize(args)
      @base_directory = args.directory
      @issue_directories = Dir.glob("#{base_directory}/*")
      @uri = URI.parse "http://#{args.username}:#{args.password}@#{args.host}"
      @errors = []
    end
  
    def self.process(args)
      magazines = self.new(args)

      magazines.issue_directories.each do |directory|
        images = Dir.glob(File.join directory, '*.{jpeg,JPEG,jpg,JPG}')
        if !images.empty?
          id_file = File.join directory, 'issue_id'
      
          issue_id = if File.exists?(id_file)
            File.read id_file
          else
            magazines.errors << magazines.send(:create_issue, directory)
          end
          
          if issue_id
            magazines.send :join_images, directory
            magazines.send :upload_images, directory, issue_id
          end
        end
      end
    
      puts magazines.errors.flatten.compact.join("\n")
    end

    private

    def create_issue(directory)
      response = Net::HTTP.post_form(self.uri + '/upload/issues', {})
      if response.code == '200'
        issue_id = response.body
        File.open(File.join(directory, 'issue_id'), 'w') do |f|
          f.puts issue_id
        end
        issue_id
      else
        self.errors << "Unknown response, body: #{response.body}, code: #{response.code}"
        false
      end
    rescue => error
      self.errors << "Error creating issue, error: #{error.class}, message: #{error.message}"
      false
    end

    def upload_images(directory, issue)
      Dir.glob(File.join directory, '*.{jpeg,JPEG,jpg,JPG}') do |image|
        begin
          upload_io = UploadIO.new image, 'image/jpeg'
          multipart = Net::HTTP::Post::Multipart.new('/upload/tear_sheets', 'issue_id' => issue, 'tear_sheet[image]' => upload_io)
        
          response  = Net::HTTP.start(uri.host, uri.port) do |http|
            multipart.basic_auth uri.user, uri.password
            http.request multipart
          end
              
          if response.code == '200'
            FileUtils.rm image
          elsif response.code == '422'
            self.errors << "Invalid image, response: #{response.body}"
          else
            self.errors << "Unknown response, issue: #{issue.chomp}, image: #{image}, response: #{response.body}, code: #{response.code}"
          end

        rescue => error
          self.errors << "Error creating tear sheet '#{image}', error: #{error.class}, message: #{error.message}"
        end
      end
    end
    
    def join_images(path)
      group_join_images(path).each_value do |images|
        extension_regex = /-[a-z]*\.(?i)JPE?G/
        new_image_path  = images[0].gsub(extension_regex, '_joined.jpg')

        image = Magick::ImageList.new *images
        if image.append(false).write(new_image_path)
          images.each { |image| FileUtils.rm image }
        end
      end
    end

    def group_join_images(path, image_groups={})
      images = Dir.glob(File.join(path, '*-[a-z]*\.{jpeg,JPEG,jpg,JPG}'))
      ('a'..'z').each do |letter|
        images.delete_if do |image|
          (1..9).each do |n|
            if File.basename(image) =~ /-(#{letter}{#{n}})\./
              key = letter * n
              image_groups[key] = [] unless image_groups[key]
              image_groups[key] << image
            end
          end
        end
      end

      image_groups
    end
  
  end
end
