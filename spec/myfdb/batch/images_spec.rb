require 'spec_helper'
require 'myfdb/batch/images'

class TestImageProcessor
  include Batch::Images

  def initialize(directory, uri)
    @directory = directory
    @uri = URI.parse uri
    @id = 2
  end
end

describe Batch::Images do
  let(:test_processor) { TestImageProcessor.new directory, 'https://me:123@test.com' }

  after do
    delete_images
  end

  context '#images' do
    it 'returns an array' do
      test_processor.images.should be_an(Array)
    end

    it 'returns an array of paths' do
      create_images

      test_processor.images.should have(4).paths
    end
  end

  context '#images?' do
    it 'returns false if images is empty' do
      test_processor.images?.should be_false
    end

    it 'returns false if images is empty' do
      Dir.stubs(:glob).returns([1,2,3,4,5])
      test_processor.images?.should be_true
    end
  end

  context '#process_images' do
    it 'invokes #seperate_images_to_join, #join, #upload if id' do
      test_processor.expects(:upload)
      test_processor.process_images
    end

    it 'does nothing if id not set' do
      test_processor.expects(:id).returns(nil)
      test_processor.expects(:upload).never
      test_processor.process_images
    end
  end

  describe '#upload' do
    context 'error' do
      before do
        %x(touch #{directory}/test.jpg)
        Net::HTTP.
          expects(:start).
          at_least_once.
          with('test.com', 443).
          raises(NoMethodError, 'General error')
        test_processor.send(:upload)
      end
      
      it 'connection error' do
        test_processor.errors.first.should eql("Error creating tear sheet 'test.jpg', error: NoMethodError, message: General error")
      end
    end
  end

end

def directory
  fixtures_directory + '/images'
end

def create_images
  %w(jpeg JPEG jpg JPG tiff).each_with_index do |ext, i|
    %x(touch #{directory}/#{i}_test.#{ext})
  end 
end

def create_join_images
  FileUtils.cp_r Dir.glob("#{fixtures_directory}/join_images/*"), directory
end

def delete_images
  Dir.glob directory + '/*' do |f|
    %x(rm #{f})
  end
end
