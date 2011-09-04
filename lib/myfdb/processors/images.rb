require 'net/http/post/multipart'
require 'rmagick'

module Processors
  # Included class must define:
  #   #directory (points to the parent directory housing the image directories)
  #   #uri (uri to the upload server)
  #   #id (id of the associated issue)
  #
  module Images
  
    def images?
      !images.empty?
    end

    def images
      Dir.glob(File.join directory, '*.{jpeg,JPEG,jpg,JPG}')
    end

    def process_images
      collect_join_groups && join && upload if id
    end

    private

    def join_groups
      @join_groups ||= {}
    end

    def join
      join_groups.each_value do |images|
        image = Magick::ImageList.new *images
        joined_image_path = images[0].gsub(/-[a-z]*\.(?i)JPE?G/, '_joined.jpg')

        if image.append(false).write(joined_image_path)
          images.each { |image| delete(image) }
        end
      end
    end

    def collect_join_groups
      images = Dir.glob(File.join directory, '*-[a-z]*\.{jpeg,JPEG,jpg,JPG}')
      ('a'..'z').each do |letter|
        images.delete_if do |image|
          (1..9).each do |n|
            if File.basename(image) =~ /-(#{letter}{#{n}})\./
              key = letter * n
              join_groups[key] = [] unless join_groups[key]
              join_groups[key] << image
            end
          end
        end
      end
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
          errors << "Error creating tear sheet '#{image}', error: #{error.class}, message: #{error.message}"
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
