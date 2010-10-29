require File.dirname(__FILE__) + '/../../spec_helper'
require 'ruby-fs-stack/identity'

describe IdentityV2::Communicator do
  include HttpCommunicatorHelper # found in the spec_helper
  
  def do_get(url, credentials = {})
    @com.get(url, credentials)
  end
  
  before(:each) do
    stub_net_objects
    @com = FsCommunicator.new :domain => 'http://www.dev.usys.org', :key => 'KEY'
  end
  
  it "should have an extended identity_v1 method on the communicator" do
    @com.identity_v1.should be_instance_of(IdentityV2::Communicator)
  end
  
  # At this point, we're making an alias on identity_v1 to just use identity_v2 so that you don't have to make 
  # that many code changes in your clients
  describe "authenticate (v1)" do
    before(:each) do
      filename = File.join(File.dirname(__FILE__),'json','login.js')
      @body = File.read(filename)
      @mock_response = mock('HTTP::Response', :body => @body, :code => '200')
      @http.should_receive(:start).and_return(@mock_response)
      @request.should_receive(:basic_auth).with('user','pass')
      @request.should_receive(:[]=).with('User-Agent',@com.user_agent)
    end
    
    it "should make a call to /identity/v2/login" do
      url = "/identity/v2/login?key=KEY"
      Net::HTTP::Get.should_receive(:new).with(url+"&dataFormat=application/json").and_return(@request)
      response = @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
    end
    
    it "should return true if successful" do
      success = @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
      success.should == true
    end
    
    it "should set the communicator's session to the logged in session" do
      @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
      @com.session.should == 'USYS5E027A421416AA29BA0A348A84CEA5C9_nbci-045-034'
    end
    
    it "should raise RubyFsStack::Unauthorized if the login was not successful" do
      @mock_response.stub!(:code).and_return('401')
      @mock_response.stub!(:message).and_return('Invalid name or password.')
      lambda{
        @com.identity_v1.authenticate(:username => 'user', :password => 'pass')
      }.should raise_error(RubyFsStack::Unauthorized)
    end
    
    describe "login" do
      it "should accept the login method and behave the same way" do
        url = "/identity/v2/login?key=KEY"
        Net::HTTP::Get.should_receive(:new).with(url+"&dataFormat=application/json").and_return(@request)
        response = @com.identity_v1.login(:username => 'user', :password => 'pass')
      end
      
      it "should return true if successful" do
        success = @com.identity_v1.login(:username => 'user', :password => 'pass')
        success.should == true
      end

      it "should set the communicator's session to the logged in session" do
        @com.identity_v1.login(:username => 'user', :password => 'pass')
        @com.session.should == 'USYS5E027A421416AA29BA0A348A84CEA5C9_nbci-045-034'
      end

      it "should raise RubyFsStack::Unauthorized if the login was not successful" do
        @mock_response.stub!(:code).and_return('401')
        @mock_response.stub!(:message).and_return('Invalid name or password.')
        lambda{
          @com.identity_v1.login(:username => 'user', :password => 'pass')
        }.should raise_error(RubyFsStack::Unauthorized)
      end
      
    end
  end
  
  describe "authenticate (v2)" do
    before(:each) do
      filename = File.join(File.dirname(__FILE__),'json','login.js')
      @body = File.read(filename)
      @mock_response = mock('HTTP::Response', :body => @body, :code => '200')
      @http.should_receive(:start).and_return(@mock_response)
      @request.should_receive(:basic_auth).with('user','pass')
      @request.should_receive(:[]=).with('User-Agent',@com.user_agent)
    end
    
    it "should make a call to /identity/v2/login" do
      url = "/identity/v2/login?key=KEY"
      Net::HTTP::Get.should_receive(:new).with(url+"&dataFormat=application/json").and_return(@request)
      response = @com.identity_v2.authenticate(:username => 'user', :password => 'pass')
    end
    
    it "should return true if successful" do
      success = @com.identity_v2.authenticate(:username => 'user', :password => 'pass')
      success.should == true
    end
    
    it "should set the communicator's session to the logged in session" do
      @com.identity_v2.authenticate(:username => 'user', :password => 'pass')
      @com.session.should == 'USYS5E027A421416AA29BA0A348A84CEA5C9_nbci-045-034'
    end
    
    it "should raise RubyFsStack::Unauthorized if the login was not successful" do
      @mock_response.stub!(:code).and_return('401')
      @mock_response.stub!(:message).and_return('Invalid name or password.')
      lambda{
        @com.identity_v2.authenticate(:username => 'user', :password => 'pass')
      }.should raise_error(RubyFsStack::Unauthorized)
    end
    
    describe "login" do
      it "should accept the login method and behave the same way" do
        url = "/identity/v2/login?key=KEY"
        Net::HTTP::Get.should_receive(:new).with(url+"&dataFormat=application/json").and_return(@request)
        response = @com.identity_v2.login(:username => 'user', :password => 'pass')
      end
      
      it "should return true if successful" do
        success = @com.identity_v2.login(:username => 'user', :password => 'pass')
        success.should == true
      end

      it "should set the communicator's session to the logged in session" do
        @com.identity_v2.login(:username => 'user', :password => 'pass')
        @com.session.should == 'USYS5E027A421416AA29BA0A348A84CEA5C9_nbci-045-034'
      end

      it "should raise RubyFsStack::Unauthorized if the login was not successful" do
        @mock_response.stub!(:code).and_return('401')
        @mock_response.stub!(:message).and_return('Invalid name or password.')
        lambda{
          @com.identity_v2.login(:username => 'user', :password => 'pass')
        }.should raise_error(RubyFsStack::Unauthorized)
      end
      
    end
  end
  
end