require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/identity'

describe FsCommunicator do
  include HttpCommunicatorHelper # found in the spec_helper
  
  def do_get(url, credentials = {})
    @com.get(url, credentials)
  end
  
  before(:each) do
    stub_net_objects
    @com = FsCommunicator.new :domain => 'http://www.dev.usys.org', :key => 'KEY'
  end
  
  it "should have an extended identity_v1 method on the communicator" do
    @com.identity_v1.should be_instance_of(IdentityV1::Communicator)
  end
  
  describe "authenticate" do
    before(:each) do
      filename = File.join(File.dirname(__FILE__),'json','login.js')
      body = File.read(filename)
      @mock_response = mock('HTTP::Response', :body => body)
      @http.should_receive(:start).and_return(@mock_response)
      @request.should_receive(:basic_auth).with('user','pass')
      @request.should_receive(:[]=).with('User-Agent',@com.user_agent)
    end
    
    it "should make a call to /identity/v1/login" do
      url = "/identity/v1/login?key=KEY"
      Net::HTTP::Get.should_receive(:new).with(url+"&dataFormat=application/json").and_return(@request)
      response = @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
    end
    
    it "should return an Org::Familysearch::Ws::Identity::V1::Schema::Identity object" do
      identity = @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
      identity.should be_instance_of(Org::Familysearch::Ws::Identity::V1::Schema::Identity)
      identity.session.id.should == 'USYS6325F49E7E47C181EA7E73E897F9A8ED.ptap009-034'
    end
    
  end
end