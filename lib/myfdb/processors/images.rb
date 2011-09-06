require 'net/http/post/multipart'
require 'rmagick'

module Processors
  module Images
    
    def self.included(base)
      base.class_eval do
        attr_reader :directory, :id, :uri

        def errors
          @errors ||= []
        end
      end
    end
  
    def images?
      !images.empty?
    end

    def images
      Dir.glob(File.join directory, '*.{jpeg,JPEG,jpg,JPG}')
    end

    def process_images
      join && upload if id
    end

    def join_groups
      @join_groups ||= group_images_to_join
    end

    private

    def join
      join_groups.each_value do |images|
        image = Magick::ImageList.new *images
        joined_image_path = images[0].gsub(/-[a-z]*\.(?i)JPE?G/, '_joined.jpg')

        if image.append(false).write(joined_image_path)
          images.each { |image| delete(image) }
        end
      end
    end

    def group_images_to_join(join_groups={})
      images = Dir.glob(File.join directory, '*-[a-z]*\.{jpeg,JPEG,jpg,JPG}')
      ('a'..'z').each do |letter|
        images.each do |image|
          (1..9).each do |n|
            if File.basename(image) =~ /-(#{letter}{#{n}})\./
              key = letter * n
              join_groups[key] = [] unless join_groups[key]
              join_groups[key] << image
            end
          end
        end
      end
      join_groups
    end

    def upload
      images.each do |image|
        begin
          uri_path  = '/upload/tear_sheets'
          upload_io = UploadIO.new(image, 'image/jpeg')
          multipart = Net::HTTP::Post::Multipart.new(uri_path, 'issue_id' => id.to_s, 'tear_sheet[image]' => upload_io)
        
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            multipart.basic_auth uri.user, uri.password
            http.request multipart
          end
              
          if error = parse_response(response)
            errors << error
          else
            delete(image)
          end
        rescue => error
          errors << "Error creating tear sheet '#{File.basename(image)}', error: #{error.class}, message: #{error.message}"
        end
      end
    end

    def parse_response(response)
      case response.code
      when '200'
        nil
      when '422'
        "Invalid image, response: #{response.body}"
      else
        "Unknown response, issue: #{id}, response: #{response.body}, code: #{response.code}"
      end
    end

    def delete(image)
      FileUtils.rm(image) and return nil
    end

  end
end
