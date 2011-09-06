require 'spec_helper'
require 'myfdb/processors/images'

class TestImageProcessor
  include Processors::Images

  def initialize(directory, uri)
    @directory = directory
    @uri = URI.parse uri
    @id = 2
  end
end

describe Processors::Images do
  let(:test_processor) { TestImageProcessor.new directory, 'http://me:123@test.com' }

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
      test_processor.expects(:join).returns(true)
      test_processor.expects(:upload)
      test_processor.process_images
    end

    it 'does nothing if id not set' do
      test_processor.expects(:id).returns(nil)
      test_processor.expects(:join).never
      test_processor.expects(:upload).never
      test_processor.process_images
    end
  end

  context '#join_groups' do
    let(:expected) do 
      {
        "a" => ["#{directory}/0_test_0-a.jpg", "#{directory}/0_test_1-a.jpg"],
        "aa" => ["#{directory}/1_test_0-aa.jpg", "#{directory}/1_test_1-aa.jpg"],
        "b" => ["#{directory}/2_test_0-b.jpg", "#{directory}/2_test_1-b.jpg"],
        "bb" => ["#{directory}/3_test_0-bb.jpg", "#{directory}/3_test_1-bb.jpg"],
        "bbb" => ["#{directory}/4_test_0-bbb.jpg", "#{directory}/4_test_1-bbb.jpg", "#{directory}/4_test_2-bbb.jpg" ]
      }
    end

    it 'groups images appended by alphabet into a hash' do
      create_images
      create_join_images
      test_processor.join_groups.should eql(expected) 
    end

    it 'returns an empty hash if no images exist' do
      test_processor.join_groups.should eql({})
    end
  end

  context '#join' do
    before do
      create_join_images
      test_processor.send(:join)
    end

    it 'merges related images into one image' do
      images = Dir.glob(File.join directory, '*')
      images.should have(5).images
    end

    it 'deletes the original images after merging complete' do
      images = Dir.glob(File.join directory, '*')
      images.each do |image|
        image.should match(/_joined.jpg/)
      end
    end
  end

  describe '#upload' do
    context 'error' do
      before do
        %x(touch #{directory}/test.jpg)
        Net::HTTP.
          expects(:start).
          at_least_once.
          with('test.com', 80).
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
