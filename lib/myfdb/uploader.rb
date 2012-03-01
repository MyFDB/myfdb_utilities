require 'myfdb/batch'

module Myfdb
  module Uploader
  
    def self.process(options)
      uri = URI.parse "http://#{options.key}:#{options.secret}@#{options.host}"
      batches = []

      Dir.glob("#{options.directory}/*") do |directory|
        batch = Myfdb::Batch.new(directory, uri)
        batch.store! 
        batches << batch
      end

      process_errors batches
    end

    private

    def self.process_errors(batches)
      batches.each do |batch|
        unless batch.errors.empty?
          puts "Errors for issue ##{batch.id}:"
          batch.errors.compact.each do |error|
            puts error
          end
        end
      end
    end

  end
end
