require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RubyFsStack do
  describe "version" do
    before(:each) do
      
      @version = File.read(File.join(File.dirname(__FILE__),'..','VERSION')).strip
    end
    
    it "should read the version from the file" do
      RubyFsStack.version.should == @version
    end
  end
end
