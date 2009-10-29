$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'ruby-fs-stack'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

module HttpCommunicatorHelper
  
  def stub_net_objects
    @request = mock("Net::HTTP::Get|Post")
    @request.stub!(:[]=)
    @request.stub!(:body=)
    @http = mock("Net::HTTP")
    Net::HTTP.stub!(:new).and_return(@http)
    Net::HTTP::Get.stub!(:new).and_return(@request)
    Net::HTTP::Post.stub!(:new).and_return(@request)
    @http.stub!(:use_ssl=)
    @http.stub!(:ca_file=)
    @http.stub!(:verify_mode=)
    @http.stub!(:start)
  end
  
end