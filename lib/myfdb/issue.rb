require 'myfdb/processors/images'

module Myfdb
  class Issue
    include Processors::Images
    
    attr_reader :id, :directory, :uri, :errors

    def initialize(directory, uri)
      @directory = directory
      @errors = []
      @uri = uri
    end

    def save
      retrieve_id && process_images if images?
    end

    private

    def retrieve_id
      @id = File.read(File.join directory, 'issue_id')
    rescue Errno::ENOENT
      response = create_issue(directory)
      response.is_a?(Integer) ? @id = response : errors << response 
    end

    def create_issue(dir)
      response = Net::HTTP.post_form(self.uri + '/upload/issues', {})
      if response.code == '200'
        id = response.body.to_i
        File.open(File.join(dir, 'issue_id'), 'w') do |f|
          f.print id
        end
        id
      else
        errors << "Unknown response, body: #{response.body}, code: #{response.code}" and return nil
      end
    rescue => error
      errors << "Error creating issue, error: #{error.class}, message: #{error.message}" and return nil
    end

  end
end
