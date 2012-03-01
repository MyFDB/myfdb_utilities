require 'myfdb/batch/images'

module Myfdb
  class Batch
    include ::Batch::Images
    
    attr_reader :directory, :uri, :errors

    def initialize(directory, uri)
      @directory = directory
      @errors = []
      @uri = uri
    end

    def store!
      id && process_images if images?
    end

    def id
      @id ||= File.read(File.join directory, 'issue_id')
    rescue Errno::ENOENT
      response = create_issue
      response.is_a?(Integer) ? @id = response : errors << response 
    end

    private

    def create_issue
      response = Net::HTTP.post_form(self.uri + '/upload/issues', {})
      if response.code == '200'
        id = response.body.to_i
        File.open(File.join(directory, 'issue_id'), 'w') do |f|
          f.print id
        end
        id
      else
        "Unknown response, body: #{response.body}, code: #{response.code}"
      end
    rescue => error
      "Error creating issue, error: #{error.class}, message: #{error.message}"
    end

  end
end
