 require File.dirname(__FILE__) + '/spec_helper'
require 'ruby-fs-stack/fs_communicator'

describe FsCommunicator do
  include HttpCommunicatorHelper
  describe "initializing" do
    it "should accept a hash of options" do
      lambda {
        com = FsCommunicator.new :domain => 'https://api.familysearch.org', :key => '1111-1111', :user_agent => "FsCommunicator/0.1"
      }.should_not raise_error
    end
    
    it "should set defaults to the Reference System" do
      com = FsCommunicator.new
      com.domain.should == 'http://www.dev.usys.org'
      com.key.should == ''
      com.user_agent.should == 'FsCommunicator/0.1 (Ruby)'
      com.handle_throttling.should == false
    end
    
    it "should set the domain, key, and user_agent to options hash" do
      options = {
        :domain => 'https://api.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "RSpecTest/0.1",
        :session => 'SESSID',
        :handle_throttling => true
      }
      com = FsCommunicator.new options
      com.domain.should == options[:domain]
      com.key.should == options[:key]
      com.user_agent.should == options[:user_agent]
      com.session.should == options[:session]
      com.handle_throttling.should == true
    end
  end
  
  describe "GET on a URL" do
    before(:each) do
      options = {
        :domain => 'https://api.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID'
      }
      @com = FsCommunicator.new options
      stub_net_objects #found in the spec helper
      @url = '/familytree/v1/person/KWQS-BBQ'
      @session_url = @url + "?sessionId=#{@com.session}&dataFormat=application/json"
      @res = mock('HTTP::Response')
      @res.stub!(:code).and_return('200')
      @http.stub!(:start).and_return(@res)
    end
    
    def do_get(url, credentials = {})
      @com.get(url, credentials)
    end
    
    it "should initialize a Net::HTTP object to make the request" do
      Net::HTTP.should_receive(:new).with('api.familysearch.org',443).and_return(@http)
      do_get(@url)
    end
    
    it "should create a GET request with url containing a session" do
      Net::HTTP::Get.should_receive(:new).with(@session_url).and_return(@request)
      do_get(@url)
    end
    
    it "should tack a sessionId as an additional parameter if params already set" do
      url = "/familytree/v1/person/KWQS-BBQ?view=summary"
      Net::HTTP::Get.should_receive(:new).with(url+"&sessionId=#{@com.session}&dataFormat=application/json").and_return(@request)
      do_get(url)
    end
    
    it "should set the http object to use ssl if https" do
      @http.should_receive(:use_ssl=).with(true)
      do_get(@url)
    end
    
    it "should not set the http object to use ssl if no http" do
      @com.domain = 'http://www.dev.usys.org'
      @http.should_not_receive(:use_ssl=)
      do_get(@url)
    end
    
    it "should set the ca file to the entrust certificate (for FamilySearch systems)" do
      @http.should_receive(:ca_file=).with(File.join(File.dirname(__FILE__),'..','lib','ruby-fs-stack','assets','entrust-ca.crt'))
      do_get(@url)
    end
    
    it "should set the basic_authentication if the credentials passed as parameters" do
      @request.should_receive(:basic_auth).with('user','pass')
      @request.should_receive(:[]=).with('User-Agent',@com.user_agent)
      Net::HTTP::Get.should_receive(:new).with(@url+"?key=#{@com.key}&dataFormat=application/json").and_return(@request)
      do_get(@url,:username => 'user',:password => 'pass')
    end
    
    it "should make the request" do
      block = lambda{ |ht|
        ht.request('something')
      }
      @http.should_receive(:start)
      do_get(@url)
    end
    
    it "should sleep and call again if handle_throttling is set to true and the response code is 503" do
      @com.handle_throttling = true
      @res.stub!(:code).and_return('503','200')
      @http.stub!(:start).and_return(@res)
      @com.should_receive(:sleep).once
      do_get(@url)
    end
    
    it "should not call sleep if handle_throttling is set to false" do
      @com.handle_throttling = false
      @res.stub!(:code).and_return('503','200')
      @http.stub!(:start).and_return(@res)
      @com.should_not_receive(:sleep)
      do_get(@url)
    end
    
  end
  
  describe "POST on a URL" do
    before(:each) do
      options = {
        :domain => 'https://api.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID'
      }
      @com = FsCommunicator.new options
      stub_net_objects
      @url = '/familytree/v1/person/KWQS-BBQ'
      @session_url = @url + "?sessionId=#{@com.session}&dataFormat=application/json"
      @payload = "<familytree></familytree>"
      @res = mock('HTTP::Response')
      @res.stub!(:code).and_return('200')
      @http.stub!(:start).and_return(@res)
    end
    
    def do_post(url, payload = '')
      @com.post(url, payload)
    end
    
    it "should initialize a Net::HTTP object to make the request" do
      Net::HTTP.should_receive(:new).with('api.familysearch.org',443).and_return(@http)
      do_post(@url)
    end
    
    it "should create a POST request with url containing a session" do
      Net::HTTP::Post.should_receive(:new).with(@session_url).and_return(@request)
      do_post(@url)
    end
    
    it "should tack a sessionId as an additional parameter if params already set" do
      url = "/familytree/v1/person/KWQS-BBQ?view=summary"
      Net::HTTP::Post.should_receive(:new).with(url+"&sessionId=#{@com.session}&dataFormat=application/json").and_return(@request)
      do_post(url)
    end
    
    it "should set the request's body to the payload attached" do
      @request.should_receive(:body=).with(@payload)
      do_post(@url,@payload)
    end
    
    it "should set the request's Content-Type to application/json" do
      @request.should_receive(:[]=).with('Content-Type','application/json')
      do_post(@url,@payload)
    end
    
    it "should set the http object to use ssl if https" do
      @http.should_receive(:use_ssl=).with(true)
      do_post(@url)
    end
    
    it "should not set the http object to use ssl if no http" do
      @com.domain = 'http://www.dev.usys.org'
      @http.should_not_receive(:use_ssl=)
      do_post(@url)
    end
    
    it "should set the ca file to the entrust certificate (for FamilySearch systems)" do
      @http.should_receive(:ca_file=).with(File.join(File.dirname(__FILE__),'..','lib','ruby-fs-stack','assets','entrust-ca.crt'))
      do_post(@url)
    end
        
    it "should make the request" do
      block = lambda{ |ht|
        ht.request('something')
      }
      @http.should_receive(:start)
      do_post(@url)
    end
    
    it "should sleep and call again if handle_throttling is set to true and the response code is 503" do
      @com.handle_throttling = true
      @res.stub!(:code).and_return('503','200')
      @http.stub!(:start).and_return(@res)
      @com.should_receive(:sleep).once
      do_post(@url)
    end
    
    it "should not call sleep if handle_throttling is set to false" do
      @com.handle_throttling = false
      @res.stub!(:code).and_return('503','200')
      @http.stub!(:start).and_return(@res)
      @com.should_not_receive(:sleep)
      do_post(@url)
    end
    
  end
  
end