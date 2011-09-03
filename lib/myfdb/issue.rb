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
      join_images
      upload_images
    end

    private

    def retrieve_or_create_issue_id
      File.read File.join(directory, 'issue_id')
    rescue Errno::ENOENT
      errors << create_issue(directory)
    end

    def create_issue(dir)
      response = Net::HTTP.post_form(self.uri + '/upload/issues', {})
      if response.code == '200'
        issue_id = response.body
        File.open(File.join(dir, 'issue_id'), 'w') do |f|
          f.puts issue_id
        end
        issue_id
      else
        errors << "Unknown response, body: #{response.body}, code: #{response.code}"
        nil
      end
    rescue => error
      errors << "Error creating issue, error: #{error.class}, message: #{error.message}"
      nil
    end

  end
end
