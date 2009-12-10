require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'

describe Org::Familysearch::Ws::Familytree::V2::Schema::MatchResults, "parsing match results" do
  FamilyTreeV2 = Org::Familysearch::Ws::Familytree::V2::Schema
  
  def read_file(filename)
    fname = File.join(File.dirname(__FILE__),'json',filename)
    File.read(fname)
  end
  
  before(:all) do
    json = read_file('match_KW3B-NNM.js')
    familytree = FamilyTreeV2::FamilyTree.from_json JSON.parse(json)
    @match = familytree.matches[0]
    @results = @match.results
  end
  
  it "should have a count of 4" do
    @match.count.should == 4
  end
  
  it "should parse an xml string and return a MatchResult object" do
    @results.first.should be_instance_of(FamilyTreeV2::MatchResult)
  end
  
  it "should have 4 result" do
    @results.should have(4).thing
  end
  
  it "should have first result with ref of KW3B-VC8" do
    @results.first.ref.should eql('KW3B-VC8')
  end
  
  it "should have first result with a confidence of High" do
    @results.first.confidence.should eql('High')
  end
  
  describe "first match person" do
    before(:all) do
      match = @results.first
      @person = match.person
    end
    
    it "should keep an alias for ref for v1 migration" do
      @person.ref.should == 'KW3B-VC8'
    end
    
    it "should have name of John Flack" do
      @person.name.should eql('John Flack')
    end
    
    it "should be male" do
      @person.gender.should eql('Male')
    end
    
    it "should have 4 events" do
      @person.events.should have(4).things
    end
    
    it "should have birth date of 5 June 1880" do
      @person.birth.date.original.should eql('5 June 1880')
    end
        
    it "should have death date of 5 Aug 1953" do
      @person.death.date.original.should eql('5 Aug 1953')
    end
        
  end
  
  describe "first result person's father" do
    before(:all) do
      match = @results.first
      @person = match.father
    end
    
    it "should have name of Alfred Flack" do
      @person.name.should eql('Alfred Flack')
    end
    
    it "should be male" do
      @person.gender.should eql('Male')
    end
    
    it "should have 0 events" do
      @person.events.should have(0).things
    end
    
    it "should have nil birth" do
      @person.birth.should be_nil
    end    
  end

  describe "first result person's mother" do
    before(:all) do
      match = @results.first
      @person = match.mother
    end
    
    it "should have name of Sarah Lunt" do
      @person.name.should eql('Sarah Lunt')
    end
    
    it "should be female" do
      @person.gender.should eql('Female')
    end
    
    it "should have 0 events" do
      @person.events.should have(0).things
    end    
  end
  
  describe "first result first spouse" do
    # Inherits from SearchResult so this doesn't need to be tested.
  end
end

