require 'net/http/post/multipart'

module Batch
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
      upload if id
    end

    private

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
