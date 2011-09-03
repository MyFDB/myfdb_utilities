require 'myfdb/processors/images'

module Myfdb
  class Issue
    include Processors::Images
    
    attr_reader :id, :directory, :uri, :errors

    def initialize(directory, uri)
      @directory = directory
      @errors = []
      @uri = uri
      @id = retrieve_or_create_issue_id
    end

    def images?
      !images.empty?
    end

    def images
      Dir.glob(File.join directory, '*.{jpeg,JPEG,jpg,JPG}')
    end

    def process_images
      if id
        join_images
        upload_images
      end
    end

    private

    def retrieve_or_create_issue_id
      File.read File.join(directory, 'issue_id')
    rescue Errno::ENOENT
      response = create_issue(directory)
      response.is_a?(Integer) ? response : errors << response 
    end

    def create_issue(dir)
      response = Net::HTTP.post_form(self.uri + '/upload/issues', {})
      if response.code == '200'
        issue_id = response.body
        File.open(File.join(dir, 'issue_id'), 'w') do |f|
          f.print issue_id
        end
        issue_id.to_i
      else
        errors << "Unknown response, body: #{response.body}, code: #{response.code}" and return nil
      end
    rescue => error
      errors << "Error creating issue, error: #{error.class}, message: #{error.message}" and return nil
    end

  end
end
