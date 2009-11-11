require File.dirname(__FILE__) + '/../spec_helper'

describe FamilytreeV2::Communicator do
  def read_file(filename)
    fname = File.join(File.dirname(__FILE__),'json','person',filename)
    File.read(fname)
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
  
  describe "save_person" do
    before(:each) do
      @fs_com_mock = mock("FsCommunicator")
      @res = mock("HTTP::Response")
      @json = read_file('post_response.js')
      @res.stub!(:body).and_return(@json)
      @fs_com_mock.stub!(:post).and_return(@res)
      @ft_v2_com = FamilytreeV2::Communicator.new @fs_com_mock
    end
    
    def new_person
      Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
    end
    
    def existing_person
      person_json  = read_file('KJ86-3VD_version.js')
      ft = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(person_json)
      ft.persons.first
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
  
end