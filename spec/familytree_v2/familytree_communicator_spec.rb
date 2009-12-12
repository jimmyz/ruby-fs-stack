require File.dirname(__FILE__) + '/../spec_helper'

describe FamilytreeV2::Communicator do
  FamilyTreeV2 = Org::Familysearch::Ws::Familytree::V2::Schema
  
  def read_file(filename)
    fname = File.join(File.dirname(__FILE__),'json','person',filename)
    File.read(fname)
  end
  
  def new_person
    Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
  end
  
  def existing_person
    person_json  = read_file('KJ86-3VD_version.js')
    ft = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(person_json)
    ft.persons.first
  end
  
  describe "fs_familytree_v1 call on the FsCommunicator" do
    before(:each) do
      @com = FsCommunicator.new
      @ft_com_mock = mock("FsFamilytreeV1::Communicator")
    end
    
    it "should add an fs_familytree_v1 method to the communicator" do
      @com.should respond_to(:familytree_v2)
    end

    it "should return a Communicator object when called" do
      FamilytreeV2::Communicator.should_receive(:new).with(@com).and_return(@ft_com_mock)
      famtree_com = @com.familytree_v2
      famtree_com.should == @ft_com_mock
    end
  end
  
  
  describe "person read" do
    
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @json = read_file('KJ86-3VD_all.js')
      @res.stub!(:body).and_return(@json)
      @fs_com_mock.stub!(:get).and_return(@res)
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    it "should call get on the FsCommunicator" do
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KJ86-3VD').and_return(@res)
      @ft_v2_com.person('KJ86-3VD')
    end
    
    it "should return a person of the id requested" do
      id = 'KJ86-3VD'
      person = @ft_v2_com.person(id)
      person.id.should == id
    end
    
    it "should call /familytree/v2/person if :me is requested" do
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person').and_return(@res)
      @ft_v2_com.person(:me)
    end
    
    it "should return first person in the result if :me is requested" do
      id = :me
      person = @ft_v2_com.person(:me)
      person.id.should_not be_nil
    end
    
    it "should call /familytree/v2/person?names=none if options set" do
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person?names=none').and_return(@res)
      @ft_v2_com.person(:me, :names => 'none')
    end
    
  end
  
  describe "person read w/ multiple IDs" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @json = read_file('multiple_version_read.js')
      @res.stub!(:body).and_return(@json)
      @fs_com_mock.stub!(:get).and_return(@res)
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    it "should accept an array of person IDs" do
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY,KW3B-VCB,KW3B-VC1?names=none').and_return(@res)
      results = @ft_v2_com.person ["KW3B-VCY", "KW3B-VCB", "KW3B-VC1"], :names => 'none'
      results.should be_a_kind_of(Array)
    end
  end
  
  describe "save_person" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @json = read_file('post_response.js')
      @res.stub!(:body).and_return(@json)
      @fs_com_mock.stub!(:post).and_return(@res)
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    describe "saving new persons" do
      before(:each) do
        @person = new_person
        @person.add_name 'Parker Felch'
        @person.add_gender 'Male'
        ft = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        ft.persons = [@person]
        @payload = ft.to_json
      end
      
      it "should call POST on the /familytree/v2/person url" do
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person',@payload).and_return(@res)
        @ft_v2_com.save_person(@person)
      end
      
      it "should return the person record from the response" do
        res = @ft_v2_com.save_person(@person)
        res.id.should == 'KW3B-G7P'
        res.version.should == '65537'
      end
    end
    
    describe "saving an existing person" do
      before(:each) do
        @person = existing_person
        @person.add_name 'Parker Felch'
        @person.add_gender 'Male'
        ft = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        ft.persons = [@person]
        @payload = ft.to_json
      end
      
      it "should call POST on the /familytree/v2/person/KJ86-3VD endpoint" do
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person/KJ86-3VD',@payload).and_return(@res)
        @ft_v2_com.save_person(@person)
      end
      
    end
  end
  
  describe "search" do
    
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
      
      @json = read_file('../search.js') 
      @res.stub!(:body).and_return(@json)
      @res.stub!(:code).and_return('200')
      @fs_com_mock.stub!(:get).and_return(@res)
    end
    
    it "should call the search endpoint" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/search?name=John")
      @ft_v2_com.search :name => "John"
    end
    
    it "should return the SearchResult element" do
      search_results = @ft_v2_com.search :name => "John"
      search_results.class.should == Org::Familysearch::Ws::Familytree::V2::Schema::SearchResults
      search_results.partial.should == 246
      search_results.close.should == 100
      search_results.count.should == 40
    end
    
    it "should serialize embedded parent parameters" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/search?father.name=John")
      @ft_v2_com.search :father => {:name => "John"}
    end
    
  end
  
  describe "match" do
    
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
      
      @json = read_file('../match_KW3B-NNM.js') 
      @res.stub!(:body).and_return(@json)
      @res.stub!(:code).and_return('200')
      @fs_com_mock.stub!(:get).and_return(@res)
    end
    
    it "should call the match endpoint" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/match?name=John")
      @ft_v2_com.match :name => "John"
    end
    
    it "should return the MatchResults element" do
      search_results = @ft_v2_com.match :name => "John"
      search_results.class.should == Org::Familysearch::Ws::Familytree::V2::Schema::MatchResults
      search_results.count.should == 4
    end
    
    it "should serialize embedded parent parameters" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/match?father.name=John")
      @ft_v2_com.match :father => {:name => "John"}
    end
    
    it "should accept an id as the first parameter" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/match/KWQS-BBQ")
      @ft_v2_com.match 'KWQS-BBQ'
    end
    
    it "should accept an id AND hash if passed" do
      @fs_com_mock.should_receive(:get).with("/familytree/v2/match/KWQS-BBQ?maxResults=5")
      @ft_v2_com.match 'KWQS-BBQ', :maxResults => 5
    end
    
  end
  
  describe "reading relationships" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    
    describe "for relationships that already exist" do
      before(:each) do
        @json = read_file('relationship_read.js') 
        
        @res.stub!(:body).and_return(@json)
        @res.stub!(:code).and_return('200')
        @fs_com_mock.stub!(:get).and_return(@res)              
        
      end
      
      it "should read the relationship" do
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR').and_return(@res)
        @ft_v2_com.relationship 'KWQS-BBQ', :parent => 'KWQS-BBR'
      end
      
      it "should return a person" do
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR').and_return(@res)
        person = @ft_v2_com.relationship 'KWQS-BBQ', :parent => 'KWQS-BBR'
        person.id.should == 'KWQS-BBQ'
        person.relationships.parents[0].id.should == 'KWQS-BBR'
      end
      
    end
    
  end
  
  describe "writing relationships" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    describe "for relationships that don't yet exist" do
      before(:each) do
        @json = read_file('relationship_not_found.js') 
        @res.stub!(:body).and_return(@json)
        @res.stub!(:code).and_return('404')
        @fs_com_mock.stub!(:get).and_return(@res)
        
        @post_json = read_file('relationship_update.js')
        @post_res = mock("HTTP::Response")
        @post_res.stub!(:body).and_return(@post_json)
        @fs_com_mock.stub!(:post).and_return(@post_res)
                  
        @person = new_person
        @person2 = new_person
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.stub!(:new).and_return(@person)
        
      end
      
      it "should first try to read the relationship" do
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR').and_return(@res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should create a new person with a relationship since it wasn't yet found" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @person.should_receive(:create_relationship).with(:type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological')
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should add a marriage event if sent an event key" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @person.should_receive(:create_relationship).with(:type => 'spouse', :with => 'KWQS-BBR', :event => {:type => 'Marriage', :place => 'United States', :date => '1800'})
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :event => {:type => 'Marriage', :place => 'United States', :date => '1800'}
      end
      
      it "should add an ordinances if sent an ordinance key" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @person.should_receive(:create_relationship).with(:type => 'spouse', :with => 'KWQS-BBR', :ordinance => {:type => 'Sealing_to_Spouse', :place => 'United States', :date => '1800', :temple => 'SLAKE'})
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :ordinance => {:type => 'Sealing_to_Spouse', :place => 'United States', :date => '1800', :temple => 'SLAKE'}
      end
      
      it "should post a familytree request with the person to the correct endpoint" do
        @person2.create_relationship(:type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological')
        @person2.id = 'KWQS-BBQ'
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        
        familytree.persons = [@person2]
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR', familytree.to_json).and_return(@post_res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
    end
    
    describe "for relationships that already exist" do
      before(:each) do
        @json = read_file('relationship_read.js') 
        
        @res.stub!(:body).and_return(@json)
        @res.stub!(:code).and_return('200')
        @fs_com_mock.stub!(:get).and_return(@res)
        
        @post_json = read_file('relationship_update.js')
        @post_res = mock("HTTP::Response")
        @post_res.stub!(:body).and_return(@post_json)
        @fs_com_mock.stub!(:post).and_return(@post_res)
        
        # Create a payload to compare against
        ft = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(@json)
        person = ft.persons.find{|p|p.id=='KWQS-BBQ'}
        person.create_relationship :type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological'
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        familytree.persons = [person]
        @req_payload = familytree.to_json          
                  
        @familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(@json)
        Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.stub!(:from_json).and_return(@familytree)
        
        @person = @familytree.persons.find{|p|p.id=='KWQS-BBQ'}
      end
      
      it "should first try to read the relationship" do
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR').and_return(@res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should create a new person with a relationship since it wasn't yet found" do
        @person.should_not_receive(:id=).with('KWQS-BBQ')
        @person.should_receive(:create_relationship).with(:type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological')
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should add a marriage event if sent an event key" do
        @person.should_receive(:create_relationship).with(:type => 'spouse', :with => 'KWQS-BBR', :event => {:type => 'Marriage', :place => 'United States', :date => '1800'})
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :event => {:type => 'Marriage', :place => 'United States', :date => '1800'}
      end
      
      it "should add an ordinances if sent an ordinance key" do
        @person.should_receive(:create_relationship).with(:type => 'spouse', :with => 'KWQS-BBR', :ordinance => {:type => 'Sealing_to_Spouse', :place => 'United States', :date => '1800', :temple => 'SLAKE'})
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :ordinance => {:type => 'Sealing_to_Spouse', :place => 'United States', :date => '1800', :temple => 'SLAKE'}
      end
      
      it "should post a familytree request with the person to the correct endpoint" do
        
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR', @req_payload).and_return(@post_res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
    end
  end
  
  describe "combining persons" do
    def new_person(id,version)
      p = FamilyTreeV2::Person.new
      p.id = id
      p.version = version
      p
    end
    
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @post_res = mock("HTTP::Response")
      @post_res.stub!(:body).and_return(read_file('../combine_response.js'))
      
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
      
      @persons = [new_person('KWQS-BBQ','1'),new_person('KWQS-BBR','2'),new_person('KWQS-BBB','3')]
      @ft_v2_com.stub!(:person).and_return(@persons)
      @fs_com_mock.stub!(:post).and_return(@post_res)
    end
    
    it "should accept an array of IDs and return the response person" do
      new_person = @ft_v2_com.combine ['KWQS-BBQ','KWQS-BBR','KWQS-BBB']
      new_person.should be_instance_of(FamilyTreeV2::Person)
    end
    
    it "should perform a person (version) read on all of the IDs passed" do
      @ft_v2_com.should_receive(:person).with(['KWQS-BBQ','KWQS-BBR','KWQS-BBB'],{:genders => 'none', :events => 'none', :names => 'none'}).and_return(@persons)
      result = @ft_v2_com.combine ['KWQS-BBQ','KWQS-BBR','KWQS-BBB']
    end
    
    it "should call post on /familytree/v2/person" do
      familytree = FamilyTreeV2::FamilyTree.new
      FamilyTreeV2::FamilyTree.should_receive(:new).and_return(familytree,familytree)
      familytree.should_receive(:to_json).and_return('ftjson')
      @fs_com_mock.should_receive(:post).with('/familytree/v2/person','ftjson').and_return(@post_res)
      result = @ft_v2_com.combine ['KWQS-BBQ','KWQS-BBR','KWQS-BBB']
    end
    
    it "should result in a new person record with an id and version" do
      result = @ft_v2_com.combine ['KWQS-BBQ','KWQS-BBR','KWQS-BBB']
      result.id.should == "KW3B-VZC"
      result.version.should == "65537"
    end
  end
  
end