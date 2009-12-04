require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'


describe Org::Familysearch::Ws::Familytree::V2::Schema::SearchResults do
  FamilyTreeV2 = Org::Familysearch::Ws::Familytree::V2::Schema
  
  def read_file(filename)
    fname = File.join(File.dirname(__FILE__),'json',filename)
    File.read(fname)
  end
  
  before(:each) do
    json = read_file("search.js")
    familytree = FamilyTreeV2::FamilyTree.from_json JSON.parse(json)
    @search_results = familytree.searches[0]
    @results = @search_results.results
  end
  
  it "should parse an json string and give us SearchResults" do
    @search_results.should be_instance_of(FamilyTreeV2::SearchResults)
  end
  
  it "should have 40 results" do
    @search_results.count.should == 40
    @search_results.results.should have(40).things
  end
  
  it "should have first result with ref of KW3B-NNM" do
    @results.first.id.should eql('KW3B-NNM')
    # alias ref for backwards compatibility w/ v1
    @results.first.ref.should eql('KW3B-NNM')
  end
  
  it "should have first result with a score of 5.0" do
    @search_results.results.first.score.should eql(5.0)
  end
  
  describe "first result person" do
    before(:each) do
      result = @results.first
      @person = result.person
    end
    
    it "should have name of John Flack" do
      @person.full_name.should eql('John Flack')
      # aliased name on SearchPerson for backwards compatibility w/ v1
      @person.name.should == 'John Flack'
    end
    
    it "should be male" do
      @person.gender.should eql('Male')
    end
    
    it "should have 3 events" do
      @person.events.should have(3).things
    end
    
    it "should have birth date of 5 June 1880" do
      # differs from v1 in that you must explicitly request the original
      @person.birth.date.original.should eql('5 June 1880')
    end
    
    it "should have birth place of Arizona, United States" do
      @person.birth.place.original.should eql('Arizona, United States')
    end
        
    it "should have death date of 28 Sep 1900" do
      @person.death.date.original.should eql('16 August 1952')
    end
    
    it "should have death place of Mesa, Maricopa, Arizona, United States" do
      @person.events.to_json
      @person.death.place.original.should eql('Mesa, Maricopa, Arizona, United States')
    end
    
  end
  
  describe "first result person's father" do
    before(:each) do
      result = @results.first
      @person = result.father
    end
    
    it "should have name of Alfred Flack" do
      @person.name.should eql('Alfred Flack')
    end
    
    it "should be male" do
      @person.gender.should eql('Male')
    end
    
  end
  
  describe "first result person's mother" do
    before(:each) do
      result = @results.first
      @person = result.mother
    end
    
    it "should have name of Sarah Lunt" do
      @person.name.should eql('Sarah Lunt')
    end
    
    it "should be male" do
      @person.gender.should eql('Female')
    end
    
  end
  
  describe "first result first spouse" do
    before(:each) do
      result = @results.first
      @person = result.spouses.first
    end
    
    it "should have name of Jane Littleton" do
      @person.name.should eql('Jane Littleton')
    end
    
    it "should be female" do
      @person.gender.should eql('Female')
    end
    
    it "should respond to marriage, but return nil" do
      @person.should respond_to(:marriage)
      @person.marriage.should be_nil
    end    
  end
  
end