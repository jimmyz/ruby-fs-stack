require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'

describe Org::Familysearch::Ws::Familytree::V2::Schema::Pedigree do
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
    @pedigree = @com.familytree_v2.pedigree 'KWZF-CFW'
    @pedigree.class.should == Org::Familysearch::Ws::Familytree::V2::Schema::Pedigree
  end
  
  it "should have a root element that is a PedigreePerson" do
    @pedigree.root.class.should == Org::Familysearch::Ws::Familytree::V2::Schema::PedigreePerson
    @pedigree.root.id.should == 'KWZF-CFW'
  end
  
  describe "the root" do
    it "should have a father and a mother" do
      @pedigree.root.father.id.should == 'KW8W-RFD'
      @pedigree.root.father.father.id.should == 'KN1H-HBK'
      @pedigree.root.mother.id.should == 'KW8W-RF8'
      @pedigree.root.mother.mother.id.should == '279W-NDV'
    end
    
    it "should have a full_name method" do
      @pedigree.root.full_name.should == "Francis Moroni Zimmerman"
    end
    
    it "should have a gender" do
      @pedigree.root.gender.should == 'Male'
    end
    
    it "should return nil if there is no mother or father" do
      @pedigree.root.mother.mother.mother.mother.mother.should be_nil
      @pedigree.root.father.father.father.father.father.should be_nil
    end
  end
  
  describe "person_ids" do
    it "should return an array of person ids" do
      @pedigree.person_ids.should be_instance_of(Array)
      @pedigree.person_ids.size.should == 29
    end
  end
  
  describe "continue_nodes" do
    it "should return an array of PedigreePersons that are at the edge of the pedigree" do
      @pedigree.continue_nodes.should be_instance_of(Array)
      @pedigree.continue_nodes.size.should == 8
    end
    
    describe "continue_node_ids" do
      it "should return an array of IDs for the edge people that we have in the pedigree" do
        @pedigree.continue_node_ids.should be_instance_of(Array)
      end
    end
    
    describe "continue_ids" do
      it "should return an array of IDs that are needed to continue the pedigree" do
        @pedigree.continue_ids.should be_instance_of(Array)
      end
    end
  end
  
  describe "stitching pedigrees with injest" do
    before(:each) do
      response = File.join(File.dirname(__FILE__),'json','fakeweb_pedigree2.txt')
      FakeWeb.register_uri(:get, "https://fakeweb.familysearch.org/familytree/v2/pedigree/KG9T-DVW?sessionId=SESSID&dataFormat=application/json", 
                          :response => response)
      @pedigree2 = @com.familytree_v2.pedigree 'KG9T-DVW'
      @pedigree2.root.id.should == 'KG9T-DVW'
      @master_pedigree = Org::Familysearch::Ws::Familytree::V2::Schema::Pedigree.new
    end
    
    it "should set the first pedigree's root to the new root if empty" do
      @master_pedigree.injest @pedigree
      @master_pedigree.root.id.should == @pedigree.root.id
    end
    
    it "should add the injested pedigree's persons to the :persons attr" do
      @master_pedigree.injest @pedigree
      @master_pedigree.injest @pedigree2
      @master_pedigree.persons.size.should == @pedigree.persons.size + @pedigree2.persons.size
    end
    
    it "should set :pedigree attr of each of the PedigreePersons to the master pedigree" do
      @master_pedigree.injest @pedigree
      @master_pedigree.persons.each do |p|
        p.pedigree.should == @master_pedigree
      end
    end
    
    it "should merge the person_hash to the hash of the injested pedigree" do
      @master_pedigree.injest @pedigree
      @master_pedigree.person_hash['KWZF-CFW'].should == @pedigree.root
    end
    
    it "should allow the pedigree to be traversed from the root to the end node" do
      @master_pedigree.injest @pedigree
      @master_pedigree.injest @pedigree2
      @master_pedigree.root.father.id.should == 'KW8W-RFD'
      @master_pedigree.root.father.father.father.father.father.father.father.father.father.id.should == '2HK1-VSF'
      @master_pedigree.root.father.father.father.father.father.father.father.father.father.full_name.should == 'Hans Zimmermann'
    end
  end
  
  describe "adding one person at a time via << " do 
    
    def parse_person(filename = 'KJ86-3VD_parents_families.js')
      fname = File.join(File.dirname(__FILE__),'json','person',filename)
      json_hash = JSON.parse(File.read(fname))
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json(json_hash)
      familytree.persons[0]
    end
    
    before(:each) do
      @person1 = parse_person
      @person2 = Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
      @person2.id = 'KJ86-3VW'
      @master_pedigree = Org::Familysearch::Ws::Familytree::V2::Schema::Pedigree.new
    end
    
    it "should add the person to the root if it is the first one" do
      @master_pedigree << @person1
      @master_pedigree.root.id.should == @person1.id
    end
    
    it "should convert the Person into a PedigreePerson" do
      @master_pedigree << @person1
      @master_pedigree.root.should be_instance_of(Org::Familysearch::Ws::Familytree::V2::Schema::PedigreePerson)
    end
    
    it "should have the assertions, families, and parents of the original person" do
      @master_pedigree << @person1
      @master_pedigree.root.assertions.should == @person1.assertions
      @master_pedigree.root.families.should == @person1.families
      @master_pedigree.root.parents.should == @person1.parents
    end
    
    it "should set the PedigreePerson's :pedigree to the containing pedigree" do
      @master_pedigree << @person1
      @master_pedigree.root.pedigree.should == @master_pedigree
    end
    
    it "should be able to get the person" do
      @master_pedigree << @person1
      @master_pedigree.get_person(@person1.id).id.should == @person1.id
    end
  end
  
    
end