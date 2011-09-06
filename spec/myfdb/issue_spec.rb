require 'spec_helper'
require 'myfdb/issue'

describe Myfdb::Issue do
  describe '.upload' do
    before(:each) do
      @from_directory = FIXTURES
      @to_host = HOST
    end

    context 'with a new issue' do
      before(:each) do
        @issue = Issue.new
        @issue_directory = File.join @from_directory, @issue.name
        FileUtils.mkdir @issue_directory
        FileUtils.touch File.join(@issue_directory, 'image.jpg')
        FileUtils.touch File.join(@issue_directory, 'image.gif')

        @old_untitled_tear_sheet_count = @issue.untitled_tear_sheets.count
        TearSheet.
          any_instance.
          stubs(:save_attached_files)

        FakeWeb.register_uri(:post, 
                             %r{#{@to_host}/upload/issues},
                             :body => @issue.id.to_s)
        FakeWeb.register_uri(:post, 
                             %r{#{@to_host}/upload/tear_sheets},
                             :body => '',
                             :status => '200')
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'uploads its images' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        
        puts error_report.inspect
        error_report.should be_empty

        id_file_exists = File.exists? File.join(@issue_directory, 'issue_id')
        id_file_exists.should be
      end
    end

    context 'with an issue that was partially uploaded' do
      before(:each) do
        @issue = Issue.new
        @issue_directory = File.join @from_directory, @issue.name
        FileUtils.mkdir @issue_directory
        File.open(File.join(@issue_directory, 'issue_id'), 'w') do |file|
          file.puts @issue.id
        end
        FileUtils.touch File.join(@issue_directory, 'image.jpg')

        TearSheet.
          any_instance.
          stubs(:save_attached_files)

        FakeWeb.register_uri(:post, 
                             %r{#{@to_host}/upload/tear_sheets}, 
                             :body => '',
                             :status => '200')
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'uploads its images to the existing issue' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should be_empty
      end
    end

    context 'with a unknown response when creating a new issue' do
      before(:each) do
        issue = Issue.new
        @issue_directory = File.join @from_directory, issue.name
        FileUtils.mkdir @issue_directory
        FileUtils.touch File.join(@issue_directory, 'image.jpg')
        @response_code = '500'
        @response_body = 'error'
        FakeWeb.register_uri(:post, 
                             %r{#{@to_host}/upload/issues},
                             :body => @response_body,
                             :status => @response_code)
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'returns an error report about the unknown response' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should == "Unknown response, body: #{@response_body}, code: #{@response_code}"
      end
    end

    context 'with an error when creating a new issue' do
      before(:each) do
        issue = Issue.new
        @issue_directory = File.join @from_directory, issue.name
        FileUtils.mkdir @issue_directory
        FileUtils.touch File.join(@issue_directory, 'image.jpg')
        Net::HTTP.
          expects(:post_form).
          raises('error')
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'returns an error report about the error' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should == "Error creating issue, error: RuntimeError, message: error"
      end
    end

    context 'with a issue with an invalid image' do
      before(:each) do
        issue = Issue.new
        @issue_directory = File.join @from_directory, issue.name
        FileUtils.mkdir @issue_directory
        File.open(File.join(@issue_directory, 'issue_id'), 'w') do |file|
          file.puts issue.id
        end
        FileUtils.touch File.join(@issue_directory, 'image.jpg')
        
        @response_body = 'response_body'
        FakeWeb.register_uri(:post, 
                             %r{#{HOST}/upload/tear_sheets},
                             :body => @response_body,
                             :status => '422')
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'returns an error report about the invalid image' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should == "Invalid image, response: #{@response_body}"
      end
    end

    context 'with a issue with an unknown response when uploading an image' do
      before(:each) do
        @issue = Issue.new
        @issue_directory = File.join @from_directory, @issue.name
        FileUtils.mkdir @issue_directory
        File.open(File.join(@issue_directory, 'issue_id'), 'w') do |file|
          file.puts @issue.id
        end
        @image = 'image.jpg'
        FileUtils.touch File.join(@issue_directory, @image)
        
        @response_body = 'response_body'
        @response_code = '500'
        FakeWeb.register_uri(:post, 
                             %r{#{HOST}/upload/tear_sheets},
                             :body => @response_body,
                             :status => @response_code)
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'returns an error report about the unknown response' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should == "Unknown response, issue: #{@issue.id}, image: #{@issue.name}/#{@image}, response: #{@response_body}, code: #{@response_code}"
      end
    end

    context 'with an error when uploading an image' do
      before(:each) do
        @issue = Issue.new
        @issue_directory = File.join @from_directory, @issue.name
        FileUtils.mkdir @issue_directory
        File.open(File.join(@issue_directory, 'issue_id'), 'w') do |file|
          file.puts @issue.id
        end
        @image = 'image.jpg'
        FileUtils.touch File.join(@issue_directory, @image)
        
        @error = 'error'
        Net::HTTP.
          expects(:start).
          raises(@error)
      end

      after(:each) do
        FileUtils.rm_rf @issue_directory
      end

      it 'returns an error report about the error' do
        error_report = IssuesUploader.upload @from_directory, @to_host
        error_report.should == "Error creating tear sheet '#{@issue.name}/#{@image}', error: RuntimeError, message: #{@error}"
      end
    end
  end
end
