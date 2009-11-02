require File.dirname(__FILE__) + '/spec_helper'
require 'ruby-fs-stack/fs_utils'

describe FsUtils do

  describe "querystring_from_hash" do
    it "should return a querystring" do
      qstring = FsUtils.querystring_from_hash :names => 'all'
      qstring.should == 'names=all'
    end
    
    it "should return a querystring with &s delimiting params" do
      qstring = FsUtils.querystring_from_hash :names => 'all', :events => 'all'
      # a hash never guarantees the order so we'll split the string and test
      # that it contain s all of the pieces
      qstring.should include('names=all')
      qstring.should include('events=all')
      qstring.should include('&')
    end
    
    it "should url_encode all of the hash values" do
      qstring = FsUtils.querystring_from_hash :name => "Parker Felch"
      qstring.should == 'name=Parker%20Felch'
    end
    
    it "should convert sub-hashes into key.subkey=value" do
      qstring = FsUtils.querystring_from_hash :father => {:name => 'Parker Felch'}
      qstring.should == 'father.name=Parker%20Felch'
    end
    
  end
  
end