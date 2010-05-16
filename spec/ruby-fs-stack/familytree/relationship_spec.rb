require File.dirname(__FILE__) + '/spec_helper'
require 'ruby-fs-stack/familytree'

describe Org::Familysearch::Ws::Familytree::V2::Schema::PersonRelationships do
  
  describe "add_relationship" do
    before(:each) do
      @relationships = FamTreeV2::PersonRelationships.new
    end
    
    describe "for spousal relationships" do
      it "should create the relationship of the right type" do
        @relationships.add_relationship :type => 'spouse', :with => 'KWQS-BBZ', :event => {:type => 'Marriage',:place =>"Utah, United States", :date => '15 Nov 2007'}
        @relationships.spouses.first.id.should == 'KWQS-BBZ'
        @relationships.spouses.first.assertions.events.first.value.type.should == 'Marriage'
      end
    end
    
    describe "for parent relationships" do
      it "should create the relationship of the right type" do
        @relationships.add_relationship :type => 'parent', :with => 'KWQS-BBZ', :lineage => 'Biological'
        @relationships.parents.first.id.should == 'KWQS-BBZ'
        @relationships.parents.first.assertions.characteristics.first.value.type.should == 'Lineage'
      end
    end
    
    describe "for child relationships" do
      it "should create the relationship of the right type" do
        @relationships.add_relationship :type => 'child', :with => 'KWQS-BBZ', :lineage => 'Biological'
        @relationships.children.first.id.should == 'KWQS-BBZ'
        @relationships.children.first.assertions.characteristics.first.value.type.should == 'Lineage'
      end
    end
    
  end
  
  describe "get_relationships_of_type" do
    before(:each) do
      @relationships = FamTreeV2::PersonRelationships.new
    end
    
    describe "for spousal relationships" do
      it "should return the relationship of the right type" do
        @relationships.add_relationship :type => 'spouse', :with => 'KWQS-BBZ', :event => {:type => 'Marriage',:place =>"Utah, United States", :date => '15 Nov 2007'}
        spouses = @relationships.spouses
        @relationships.get_relationships_of_type('spouse').should == spouses
        @relationships.get_relationships_of_type(:spouse).should == spouses
      end
    end
    
    describe "for parent relationships" do
      it "should return the relationship of the right type" do
        @relationships.add_relationship :type => 'parent', :with => 'KWQS-BBZ', :lineage => 'Biological'
        parents = @relationships.parents
        @relationships.get_relationships_of_type('parent').should == parents
        @relationships.get_relationships_of_type(:parent).should == parents
      end
    end
    
    describe "for child relationships" do
      it "should return the relationship of the right type" do
        @relationships.add_relationship :type => 'child', :with => 'KWQS-BBZ', :lineage => 'Biological'
        children = @relationships.children
        @relationships.get_relationships_of_type('child').should == children
        @relationships.get_relationships_of_type(:child).should == children
      end
    end
    
  end
  
end