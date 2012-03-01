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
      req = Net::HTTP::Post.new('/upload/issues')
      req.add_field 'User-Agent', 'MyFDB API 1.0'
      req.form_data = {}
      req.basic_auth uri.user, uri.password

      response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request(req) }

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
