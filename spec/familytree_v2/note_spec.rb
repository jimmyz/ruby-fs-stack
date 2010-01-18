require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'

describe Org::Familysearch::Ws::Familytree::V2::Schema::Note do
  
  describe "build" do
    
    before(:each) do
      @note = Org::Familysearch::Ws::Familytree::V2::Schema::Note.new
    end
    
    it "should receive a hash of options" do
      @note.build :personId => 'KWQS-BBQ', :assertionId => '10002', :text => "This is my note."
    end
    
    it "should build out the note according to the options" do
      @note.build :personId => 'KWQS-BBQ', :assertionId => '10002', :text => "This is my note."
      @note.person.id.should == 'KWQS-BBQ'
      @note.assertion.id.should == '10002'
      @note.text.should == "This is my note."
    end
    
    describe "building a spouses note" do
      
      before(:each) do
        @options = {:spouseIds => ['KWQS-BBQ','KWQS-BBR'],:assertionId => '10002', :text => 'MYNOTE.'}
      end
      
      it "should build the note with spouse references, assertion ID and text" do
        @note.build @options
        @note.spouses.size.should == 2
        @note.spouses[0].id.should == 'KWQS-BBQ'
        @note.spouses[1].id.should == 'KWQS-BBR'
        @note.assertion.id.should == '10002'
        @note.text = 'MYNOTE.'
      end
    end
    
    describe "building a parent-child note" do
      before(:each) do
        @options = {:parentIds => ['KWQS-BBQ'], :childId => 'KWQS-BBZ', :assertionId => '10002', :text => 'MYNOTE.'}
      end
      
      it "should build the note with spouse references, assertion ID and text" do
        @note.build @options
        @note.parents.size.should == 1
        @note.parents[0].id.should == 'KWQS-BBQ'
        @note.child.id.should == 'KWQS-BBZ'
        @note.assertion.id.should == '10002'
        @note.text = 'MYNOTE.'
      end
    end
  end
  
end