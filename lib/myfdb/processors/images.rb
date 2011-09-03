require 'net/http/post/multipart'
require 'rmagick'

module Processors
  module Images

  private

    def join_images
      sorted_groups_marked_for_join.each_value do |images|
        extension_regex = /-[a-z]*\.(?i)JPE?G/
        new_image_path  = images[0].gsub(extension_regex, '_joined.jpg')

        image = Magick::ImageList.new *images
        if image.append(false).write(new_image_path)
          images.each { |image| FileUtils.rm_rf image }
        end
      end
    end

    def sorted_groups_marked_for_join(image_groups={})
      images = Dir.glob(File.join(directory, '*-[a-z]*\.{jpeg,JPEG,jpg,JPG}'))
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

    def upload_images
      images.each do |image|
        begin
          upload_io = UploadIO.new image, 'image/jpeg'
          multipart = Net::HTTP::Post::Multipart.new('/upload/tear_sheets', 'issue_id' => id.to_s, 'tear_sheet[image]' => upload_io)
        
          response  = Net::HTTP.start(uri.host, uri.port) do |http|
            multipart.basic_auth uri.user, uri.password
            http.request multipart
          end
              
          if response.code == '200'
            FileUtils.rm image
          elsif response.code == '422'
            errors << "Invalid image, response: #{response.body}"
          else
            errors << "Unknown response, issue: #{id}, image: #{image}, response: #{response.body}, code: #{response.code}"
          end

        rescue => error
          errors << "Error creating tear sheet '#{image}', error: #{error.class}, message: #{error.message}"
        end
      end
    end

  end
end
