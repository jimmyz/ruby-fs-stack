require File.dirname(__FILE__) + '/../../spec_helper'

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
    
    describe "passing a block" do
      it "should execute the block given" do
        mock = mock('FixNum')
        mock.should_receive(:call!).once.and_return(nil)
        @ft_v2_com.person :me do |person|
          mock.call!
        end
      end
      
      it "should pass the person to the block" do
        @ft_v2_com.person :me do |person|
          person.id.should == 'KJ86-3VD'
        end
      end
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
      @props = {'person.max.ids' => 10}
      @ft_v2_com.stub!(:properties).and_return(@props)
    end
    
    it "should accept an array of person IDs" do
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY,KW3B-VCB,KW3B-VC1?names=none').and_return(@res)
      results = @ft_v2_com.person ["KW3B-VCY", "KW3B-VCB", "KW3B-VC1"], :names => 'none'
      results.should be_a_kind_of(Array)
    end
  end
  
  describe "person read w/ requesting more than the max IDs" do
    before(:each) do
      options = {
        :domain => 'https://fakeweb.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID',
      }
      @com = FsCommunicator.new options
      response = File.join(File.dirname(__FILE__),'json','fakeweb_properties.txt')
      first_batch = File.join(File.dirname(__FILE__),'json','person','fakeweb_10_batch.txt')
      second_batch = File.join(File.dirname(__FILE__),'json','person','fakeweb_6_batch.txt')
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/properties?sessionId=SESSID&dataFormat=application/json", 
                          :response => response)
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/person/KWCZ-1WL,KWCH-DGY,KWZR-RPD,KWCH-DPM,KWCH-DP9,KN1H-HBK,KLYL-KPZ,2794-46L,279W-NDV,KWJJ-5Y3?sessionId=SESSID&dataFormat=application/json", 
                          :response => first_batch)
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/person/26KN-QTT,KWCV-7F7,2NQ9-FGV,K2WM-SHZ,KCR4-MBW,KWZR-RPX?sessionId=SESSID&dataFormat=application/json", 
                          :response => second_batch)
      @properties = @com.familytree_v2.properties
    end
    
    it "should check the properties to batch the reads by the max" do
      @com.familytree_v2.should_receive(:properties).and_return(@properties)
      @com.familytree_v2.person ['KWCZ-1WL','KWCH-DGY','KWZR-RPD','KWCH-DPM','KWCH-DP9','KN1H-HBK','KLYL-KPZ','2794-46L','279W-NDV','KWJJ-5Y3']
    end
    
    it "should return an array of persons even if it exceeds the maximum" do
      results = @com.familytree_v2.person ['KWCZ-1WL','KWCH-DGY','KWZR-RPD','KWCH-DPM','KWCH-DP9','KN1H-HBK','KLYL-KPZ','2794-46L','279W-NDV','KWJJ-5Y3','26KN-QTT','KWCV-7F7','2NQ9-FGV','K2WM-SHZ','KCR4-MBW','KWZR-RPX']
      results.should have(16).things
    end
    
    describe "sending a block callback" do
      before(:each) do
        @ids = ['KWCZ-1WL','KWCH-DGY','KWZR-RPD','KWCH-DPM','KWCH-DP9','KN1H-HBK','KLYL-KPZ','2794-46L','279W-NDV','KWJJ-5Y3','26KN-QTT','KWCV-7F7','2NQ9-FGV','K2WM-SHZ','KCR4-MBW','KWZR-RPX']
      end
      
      it "should call the block for each slice of the persons requested" do
        mock = mock('FixNum')
        mock.should_receive(:call!).exactly(2).times.and_return(nil)
        @com.familytree_v2.person @ids do |persons|
          mock.call!
        end
      end
      
      it "should pass the person or persons to the block" do
        count = 0
        @com.familytree_v2.person @ids do |persons|
          count += persons.size
        end
        count.should == 16
      end
    end
  end
  
  describe "reading multiple persons when 500 errors are returned" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @json = read_file('multiple_version_read.js')
      @res.stub!(:body).and_return(@json)
      @fs_com_mock.stub!(:get).and_return(@res)
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
      @props = {'person.max.ids' => 10}
      @ft_v2_com.stub!(:properties).and_return(@props)
      
      @single_response = mock('HTTP::Response')
      single_json = read_file('KJ86-3VD_all.js')
      @single_response.stub!(:body).and_return(single_json)
    end
    
    it "should read each person separately" do
      error = RubyFsStack::ServerError.new "Nullpointer Exception", @res
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY,KW3B-VCB,KW3B-VC1?names=none').and_raise(error)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY?names=none').and_return(@single_response)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCB?names=none').and_return(@single_response)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VC1?names=none').and_return(@single_response)
      results = @ft_v2_com.person ["KW3B-VCY", "KW3B-VCB", "KW3B-VC1"], :names => 'none'
      results.should be_a_kind_of(Array)
      results.size.should == 3
    end
    
    it "should ignore a single failure and return an empty person record (with only an ID)" do
      error = RubyFsStack::ServerError.new "Nullpointer Exception", @res
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY,KW3B-VCB,KW3B-VC1?names=none').and_raise(error)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY?names=none').and_return(@single_response)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCB?names=none').and_raise(error)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VC1?names=none').and_return(@single_response)
      results = @ft_v2_com.person ["KW3B-VCY", "KW3B-VCB", "KW3B-VC1"], :names => 'none'
      results.size.should == 3
      results[1].requestedId.should == 'KW3B-VCB'
      results[1].full_name.should be_nil
    end
    
    it "should always pass an array of persons to the block" do
      error = RubyFsStack::ServerError.new "Nullpointer Exception", @res
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY,KW3B-VCB,KW3B-VC1?names=none').and_raise(error)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCY?names=none').and_return(@single_response)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VCB?names=none').and_raise(error)
      @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KW3B-VC1?names=none').and_return(@single_response)
      results = @ft_v2_com.person ["KW3B-VCY", "KW3B-VCB", "KW3B-VC1"], :names => 'none' do |persons|
        persons.should be_instance_of(Array)
        persons.size.should == 3
      end
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
        @fs_com_mock.stub!(:get).and_raise(RubyFsStack::NotFound)
        
        @post_json = read_file('relationship_update.js')
        @post_res = mock("HTTP::Response")
        @post_res.stub!(:body).and_return(@post_json)
        @fs_com_mock.stub!(:post).and_return(@post_res)
                  
        @person = new_person
        @person2 = new_person
        @generic_person = new_person
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.stub!(:new).and_return(@generic_person)
        
      end
      
      it "should first try to read the relationship" do
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR?events=none').and_return(@res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should create a new person with a relationship since it wasn't yet found" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
        @person.relationships.parents.first.id.should == 'KWQS-BBR'
      end
      
      it "should add a marriage event if sent an event key" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :event => {:type => 'Marriage', :place => 'United States', :date => '1800'}
        @person.relationships.spouses.first.id.should == 'KWQS-BBR'
      end
      
      it "should add an ordinances if sent an ordinance key" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person)
        @person.should_receive(:id=).with('KWQS-BBQ')
        @ft_v2_com.write_relationship 'KWQS-BBQ', :spouse => 'KWQS-BBR', :ordinance => {:type => 'Sealing_to_Spouse', :place => 'United States', :date => '1800', :temple => 'SLAKE'}
        @person.relationships.spouses.first.assertions.ordinances.first.value.type.should == 'Sealing_to_Spouse'
      end
      
      it "should post a familytree request with the person to the correct endpoint" do
        @person2.create_relationship(:type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological')
        @person2.id = 'KWQS-BBQ'
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        
        familytree.persons = [@person2]
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR', familytree.to_json).and_return(@post_res)
        @ft_v2_com.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBR', :lineage => 'Biological'
      end
      
      it "should post to the correct endpoint even if the related person ID changes" do
        @person2.create_relationship(:type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological')
        # Simulate a changed related ID
        @person2.relationships.parents.first.id = 'KWQS-JIM'
        @person2.relationships.parents.first.requestedId = 'KWQS-BBR'
        @person2.id = 'KWQS-BBQ'
        
        # inject this mock person into the write_relationship flow
        Org::Familysearch::Ws::Familytree::V2::Schema::Person.should_receive(:new).and_return(@person2)
        @person2.should_receive(:create_relationship)
        
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new    
        familytree.persons = [@person2]
        
        @fs_com_mock.should_receive(:post).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-JIM', familytree.to_json).and_return(@post_res)
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
        @fs_com_mock.should_receive(:get).with('/familytree/v2/person/KWQS-BBQ/parent/KWQS-BBR?events=none').and_return(@res)
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
  
  describe "writing new notes" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
      
      @response_json = read_file("../note_create_response.js")
      @res.stub!(:body).and_return(@response_json)
      
      @fs_com_mock.stub!(:post).and_return(@res)
      
      @note = Org::Familysearch::Ws::Familytree::V2::Schema::Note.new
    end
    
    describe "write_note for person assertions" do
      before(:each) do
        @options = {:personId => 'KWQS-BBQ',:assertionId => '10002', :text => 'MYNOTE.'}
      end
      
      it "should take a person ID, assertion ID, and text" do
        @ft_v2_com.write_note(@options)
      end
      
      it "should create a new Note" do
        note = Org::Familysearch::Ws::Familytree::V2::Schema::Note.new
        Org::Familysearch::Ws::Familytree::V2::Schema::Note.should_receive(:new).at_least(:once).and_return(note)
        @ft_v2_com.write_note(@options)
      end
      
      it "should build the note with the passed options" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Note.stub!(:new).and_return(@note)
        @note.should_receive(:build).with(@options)
        @ft_v2_com.write_note(@options)
      end
      
      it "should POST the note to /familytree/v2/note" do
        @note.build @options
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        familytree.notes = [@note]
        @fs_com_mock.should_receive(:post).with('/familytree/v2/note',familytree.to_json).and_return(@res)
        @ft_v2_com.write_note(@options)
      end
      
      it "should return the created note (containing the ID)" do
        result = @ft_v2_com.write_note(@options)
        result.id.should == 'ZnMtZnQucC5LVzNCLU5NRzpwLjE0MDAwMDAwNDIyOjQwMDAwM29nMlpWOTgxOVpCWWs4RjAwMA=='
      end
      
    end
    
    describe "write_note for relationships" do
      
      before(:each) do
        @options = {:spouseIds => ['KWQS-BBQ','KWQS-BBR'],:assertionId => '10002', :text => 'MYNOTE.'}
      end
      
      it "should take hash of options including the assertion ID, and text" do
        @ft_v2_com.write_note(@options)
      end
      
      it "should create a new Note" do
        note = Org::Familysearch::Ws::Familytree::V2::Schema::Note.new
        Org::Familysearch::Ws::Familytree::V2::Schema::Note.should_receive(:new).at_least(:once).and_return(note)
        @ft_v2_com.write_note(@options)
      end
      
      it "should build the note with the passed options" do
        Org::Familysearch::Ws::Familytree::V2::Schema::Note.stub!(:new).and_return(@note)
        @note.should_receive(:build).with(@options)
        @ft_v2_com.write_note(@options)
      end
      
      it "should POST the note to /familytree/v2/note" do
        @note.build @options.clone
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
        familytree.notes = [@note]
        @fs_com_mock.should_receive(:post).with('/familytree/v2/note',familytree.to_json).and_return(@res)
        @ft_v2_com.write_note(@options)
      end
      
      it "should return the created note (containing the ID)" do
        result = @ft_v2_com.write_note(@options)
        result.id.should == 'ZnMtZnQucC5LVzNCLU5NRzpwLjE0MDAwMDAwNDIyOjQwMDAwM29nMlpWOTgxOVpCWWs4RjAwMA=='
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
  
  describe "pedigree read" do
    before(:each) do
      options = {
        :domain => 'https://fakeweb.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID',
      }
      @com = FsCommunicator.new options
      response = File.join(File.dirname(__FILE__),'json','fakeweb_pedigree.txt')
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/pedigree/KWZF-CFW?sessionId=SESSID&dataFormat=application/json", 
                          :response => response)
    end
    
    it "should read the pedigree" do
      pedigree = @com.familytree_v2.pedigree 'KWZF-CFW'
      pedigree.id.should == 'KWZF-CFW'
    end
    
    it "should have persons, the first one being the requested ID" do
      pedigree = @com.familytree_v2.pedigree 'KWZF-CFW'
      pedigree.persons.first.id.should == 'KWZF-CFW'
    end
    
    describe "sending options to pedigree read" do
      before(:each) do
        response = File.join(File.dirname(__FILE__),'json','fakeweb_pedigree3.txt')
        FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/pedigree/KWZF-CFW?ancestors=9&sessionId=SESSID&dataFormat=application/json", 
                            :response => response)
      end
      
      it "should send the options to the querystring" do
        pedigree = @com.familytree_v2.pedigree 'KWZF-CFW', :ancestors => 9
        pedigree.id.should == 'ZZZZ-ZZZ'
      end
    end
    
  end
  
  describe "properties read" do
    before(:each) do
      options = {
        :domain => 'https://fakeweb.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID',
      }
      @com = FsCommunicator.new options
      response = File.join(File.dirname(__FILE__),'json','fakeweb_properties.txt')
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/properties?sessionId=SESSID&dataFormat=application/json", 
                          :response => response)
    end
    
    it "should return a hash of the properties" do
      properties = @com.familytree_v2.properties
      properties.class.should == Hash
    end
    
    it "should have the properties mapped to the hash appropriately" do
      properties = @com.familytree_v2.properties
      properties['assertion.max.notes'].should == 10
    end
    
    it "should set the properties hash to an instance attr so that it doesn't make the web call each time" do
      #don't really know how best to test this one, but it seems to be working
      properties = @com.familytree_v2.properties
      properties = @com.familytree_v2.properties
    end
        
  end
  
  describe "contributor read" do
    before(:each) do
      options = {
        :domain => 'https://fakeweb.familysearch.org', 
        :key => '1111-1111', 
        :user_agent => "FsCommunicator/0.1",
        :session => 'SESSID',
      }
      @com = FsCommunicator.new options
      response = File.join(File.dirname(__FILE__),'json','fakeweb_contributor.txt')
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/contributor?sessionId=SESSID&dataFormat=application/json", 
                          :response => response)
    end
    
    it "should return a contributor record" do
      contributor = @com.familytree_v2.contributor :me
      contributor.class.should == FamilyTreeV2::Contributor
    end
    
    it "should have an ID and contact name" do
      contributor = @com.familytree_v2.contributor :me
      contributor.id.should == 'MMDZ-8JD'
      contributor.contactName.should == 'API User 1241'
    end
            
  end
  
end