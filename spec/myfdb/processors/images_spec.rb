require 'spec_helper'
require 'myfdb/processors/images'

class TestImageProcessor
  include Processors::Images

  def initialize(directory, uri)
    @directory = directory
    @uri = uri
    @id = 2
  end
end

describe Processors::Images do
  let(:test_processor) { TestImageProcessor.new directory, '/fake/images' }

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
    let(:expected) { 
      {
        "a" => [
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/0_test_0-a.jpg",
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/0_test_1-a.jpg"
        ],
        
        "aa" => [
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/1_test_0-aa.jpg",
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/1_test_1-aa.jpg"
        ],
        
        "b" => [
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/2_test_0-b.jpg",
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/2_test_1-b.jpg"
        ],
      
        "bb" => [
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/3_test_0-bb.jpg",
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/3_test_1-bb.jpg"
        ],

        "bbb" => [
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/4_test_0-bbb.jpg",
          "/Users/lar/Sites/myfdb_utilities/spec/fixtures/magazines/4_test_1-bbb.jpg"
        ]
      }
    }

    before do
      create_join_images
    end

    it 'groups images appended by alphabet into a hash' do
      test_processor.join_groups.should eql(expected) 
    end
  end
end

def directory
  File.expand_path('../../../fixtures/magazines', __FILE__)
end

def create_images
  %w(jpeg JPEG jpg JPG tiff).each_with_index do |ext, i|
    %x(touch #{directory}/#{i}_test.#{ext})
  end 
end

def create_join_images
  2.times do |n|
    %w(a aa b bb bbb).each_with_index do |letters, i|
      %x(touch #{directory}/#{i}_test_#{n}-#{letters}.jpg)
    end 
  end
end

def delete_images
  Dir.glob directory + '/*' do |f|
    %x(rm #{f})
  end
end
