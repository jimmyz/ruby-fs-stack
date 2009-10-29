require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'


describe Org::Familysearch::Ws::Familytree::V2::Schema::Person do
  def new_person
    Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
  end
  
  def parse_person(filename = 'KJ86-3VD_all.js')
    fname = File.join(File.dirname(__FILE__),'json','person',filename)
    json_hash = JSON.parse(File.read(fname))
    familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json(json_hash)
    familytree.persons[0]
  end
  
  def add_assertions(person = nil)
    person ||= @person
    person.assertions = Org::Familysearch::Ws::Familytree::V2::Schema::PersonAssertions.new
  end
  
  describe "convenience access methods" do
    
    describe "gender" do
      
      describe "for persons with gender assertions" do
        before(:each) do
          @person = parse_person
        end
        
        it "should return the first gender value" do
          @person.gender.should == 'Male'
        end
      end
      
      describe "for nil genders or assertions" do
        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end
        
        def add_genders_array
          @person.assertions.genders = []
        end
        
        it "should return nil if no assertions" do
          @person.gender.should == nil
        end
        
        it "should return nil if no genders" do
          add_assertions
          @person.gender.should == nil
        end
        
        it "should return nil if genders is empty" do
          add_assertions
          add_genders_array
          @person.gender.should == nil
        end
        
        it "should return nil if genders[0].value is nil" do
          add_assertions
          add_genders_array
          @person.assertions.genders << stub('GenderAssertion', {:value => nil})
          @person.gender.should == nil
        end
      end  
      
    end
    
    describe "full_names" do
      describe "for persons with at least one name" do
        before(:each) do
          @person = parse_person
        end
        
        it "should return an array of strings" do
          names = @person.full_names
          names.should be_a_kind_of(Array)
          names[0].should be_a_kind_of(String)
        end
        
        it "should return an array of names" do
          names = @person.full_names
          names.first.should == "Parker Felch"
        end
        
        describe "full_name" do

          it "should return the first name" do
            @person.full_name.should == "Parker Felch"
          end
        end
      end
      
      describe "for persons without names" do
        
        def add_names_array
          @person.assertions.names = []
        end
        
        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end
        
        it "should return [] if no assertions" do
          @person.full_names.should == []
        end
        
        it "should return [] if no names" do
          add_assertions
          @person.full_names.should == []
        end
        
        it "should return [] if names is empty" do
          add_assertions
          add_names_array
          @person.full_names.should == []
        end
        
      end
      
    end
    
    describe "births" do
      describe "for persons with at least one birth event" do
        before(:each) do
          @person = parse_person
        end
        
        it "should return an array of the birth events" do
          births = @person.births
          births.should be_a_kind_of(Array)
          births.each do |e|
            e.value.type.should == 'Birth'
          end
        end
      end
      
      describe "for persons without a birth" do
        def add_events_array
          @person.assertions.names = []
        end
        
        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.births.should == []
        end

        it "should return [] if no events" do
          add_assertions
          @person.births.should == []
        end

        it "should return [] if no events of type Birth are found" do
          add_assertions
          add_events_array
          @person.births.should == []
        end
        
      end
      
    end
    
    describe "birth" do
      
      before(:each) do
        @person = parse_person
      end
      
      it "should return the 'selected' birth if an assertion is selected" do
        pending
        @person.births[1].selected = true
        @person.birth.should == @person.births[1]
      end
      
      it "should return the first birth if no assertions are selected" do
        @person.birth.should == @person.births[0]
      end
      
      it "should return nil if no births" do
        @person = parse_person('KJ86-3VD_version.js')
        @person.birth.should == nil
      end
    end
    
    
  end
  
  describe "convenience methods for adding data" do
    before(:each) do
      @person = new_person
    end
    
    it "should provide easy access method for adding a new gender assertion" do
      @person.add_gender "Male"
      @person.gender.should eql("Male")
    end

    it "should provide easy access method for adding a new name" do
      @person.add_name "Francis Zimmerman"
      @person.full_names.should include("Francis Zimmerman")
    end

    it "should parse the last name and given name and add them to the name pieces" do
      name = "John Parker /Felch/"
      @person.add_name name
      name_form = @person.assertions.names[0].value.forms[0]
      name_form.pieces.size.should == 3
      name_form.pieces.first.value.should eql('John')
      name_form.pieces[1].value.should eql('Parker')
      name_form.pieces[2].value.should eql('Felch')
      name_form.pieces[2].type.should eql('Family')
    end

    it "should provide easy access methods for assigning birth" do
      pending
      place = "Tuscarawas, Ohio, United States"
      date = "15 Jan 1844"
      @person.add_birth :place => place, :date => date
      @person.birth.place.original.should eql(place)
      @person.birth.date.original.should eql(date)
    end

    it "should provide easy access methods for assigning death" do
      pending
      place = "Tuscarawas, Ohio, United States"
      date = "16 Jan 1855"
      @person.add_death :place => place, :date => date
      @person.death.place.original.should eql(place)
      @person.death.date.original.should eql("16 Jan 1855")
    end

    it "should provide easy access method for assigning marriage (with spouse)" do
      pending
      place = "Tuscarawas, Ohio, United States"
      date = "16 Jan 1855"
      spouse = new_person
      spouse.id = 'KWQS-BBQ'
      @person.add_marriage :place => place, :date => date, :spouse => spouse.id
      @person.marriages.first.spouse.ref.should eql('KWQS-BBQ')
      @person.marriages.first.spouse.role.should eql('Unknown')
      @person.add_gender 'Female'
      @person.add_marriage :place => place, :date => date, :spouse => spouse.id
      @person.marriages.should have(2).things
      @person.marriages[1].spouse.ref.should eql('KWQS-BBQ')
      @person.marriages[1].spouse.role.should eql('Man')
    end


    it "should provide easy access method for assigning divorce (with spouse)" do
      pending
      place = "Tuscarawas, Ohio, United States"
      date = "16 Jan 1855"
      spouse = new_person
      spouse.id = 'KWQS-BBQ'
      @person.add_divorce :place => place, :date => date, :spouse => spouse.id
      @person.events.should have(1).things
      @person.events.first.type.should eql('Divorce')
    end

    it "should allow for notes to be passed as an option to an event assertion such as birth and death" do
      pending
      notes = "Found in 1880 Census."
      @person.add_birth :place => 'Tuscarawas, Ohio, United States', :notes => notes
      @person.births.first.notes.first.value.should eql(notes)
    end

    it "should allow for notes to be passed as an option for marriage and divorce" do
      pending
      marriage_note = "Found in 1850 Census."
      divorce_note = "Found in 1890 Census."
      @person.add_marriage :date => '1830', :spouse => 'KWQS-BBQ', :notes => marriage_note
      @person.add_divorce :date => '1880', :spouse => 'KWQS-BBQ', :notes => divorce_note
      @person.marriages.first.notes.first.value.should eql(marriage_note)
      @person.divorces.first.notes.first.value.should eql(divorce_note)
    end

    # Currently, there is no way of determining mother or father in the 'fact'
    # schema of an individual person. Determining father or mother must be done
    # by grabbing a parent's person document and examining gender. Therefore, it
    # is not possible to provide mother/father access directly when assigning relationships.
    # There is only a 'parent' relationship.
    it "should be able to add a parent by id and be contained in a parent_refs array" do
      pending
      @person.add_parent('KWQS-BBQ')
      @person.parent_refs.should include('KWQS-BBQ')
    end

    it "should not add another parent if the parent already exists" do
      pending
      @person.add_parent('KWQS-BBQ')
      @person.facts.should have(1).things
      @person.add_parent('KWQS-BBQ')
      @person.facts.should have(1).things
    end

    it "should add duplicate parent if force option is true" do
      pending
      @person.add_parent('KWQS-BBQ')
      @person.facts.should have(1).things
      @person.add_parent('KWQS-BBQ', :force => true)
      @person.facts.should have(2).things
    end

    it "should be able to find all parent assertions" do
      pending
      @person.add_parent('KWQS-BBQ')
      @person.add_parent('KWQS-BBP')
      @person.add_parent('KWQS-BBR')
      @person.add_parent('KWQS-BBS')
      @person.parent_assertions.should have(4).things
    end

    it "should be able to a child by and be contained in a child_refs array" do
      pending
      @person.add_child('KWQS-BBQ')
      @person.child_refs.should include('KWQS-BBQ')
    end

    it "should not add another child if the child already exists" do
      pending
      @person.add_child('KWQS-BBQ')
      @person.facts.should have(1).things
      @person.add_child('KWQS-BBQ')
      @person.facts.should have(1).things
    end

    it "should add duplicate child if the force option is set" do
      pending
      @person.add_child('KWQS-BBQ')
      @person.facts.should have(1).things
      @person.add_child('KWQS-BBQ', :force => true)
      @person.facts.should have(2).things
    end

    it "should be able to assign an id as a spouse and be contained in a spouse_refs array" do
      pending
      @person.add_spouse('KWQS-BBQ')
      @person.spouse_refs.should include('KWQS-BBQ')
    end

    it "should not add another spouse if the spouse already exists" do
      pending
      @person.add_spouse('KWQS-BBQ')
      @person.relationships.should have(1).things
      @person.add_spouse('KWQS-BBQ')
      @person.relationships.should have(1).things
    end

    it "should add a duplicate spouse if the force option is set to true" do
      pending
      @person.add_spouse('KWQS-BBQ')
      @person.relationships.should have(1).things
      @person.add_spouse('KWQS-BBQ', :force => true)
      @person.relationships.should have(2).things
    end

    it "should be able to find all parent assertions" do
      pending
      @person.add_spouse('KWQS-BBQ')
      @person.add_spouse('KWQS-BBP')
      @person.add_spouse('KWQS-BBR')
      @person.add_spouse('KWQS-BBS')
      @person.spouse_assertions.should have(4).things
    end

    describe "adding assertions with tempIds" do
      it "should be able to add a name with a tempId" do
        pending
        @person.add_name("John Hammond", :tempId => 'nameTempId')
        @person.names.first.tempId.should eql('nameTempId')
      end

      it "should be able to add a gender with a tempId" do
        pending
        @person.add_gender("Male", :tempId => 'new_gender_01')
        @person.genders.first.tempId.should eql('new_gender_01')
      end

      it "should be able to add a birth with tempId" do
        pending
        @person.add_birth :date => 'Jun 1809', :place => 'United States', :tempId => '54321'
        @person.births.first.tempId.should eql('54321')
      end

      it "should be able to add a death with tempId" do
        pending
        @person.add_death :date => 'Jun 1809', :place => 'United States', :tempId => '54321'
        @person.deaths.first.tempId.should eql('54321')
      end

      it "should be able to add a parent with a tempId" do
        pending
        @person.add_parent '5535-12W', :tempId => '54321'
        @person.parent_assertions.first.tempId.should eql('54321')
      end

      it "should be able to add a child with a tempId" do
        pending
        @person.add_child '5545-33R', :tempId => '67843'
        @person.child_assertions.first.tempId.should eql('67843')
      end

      it "should be able to add a marriage with a tempId" do
        pending
        @person.add_marriage :date => 'Jun 1809', :place => 'United States', :spouse => 'KWQS-BBQ', :tempId => '0987'
        @person.marriages.first.tempId.should eql('0987')
      end

      it "should be able to add a spouse with a tempId" do
        pending
        @person.add_spouse 'KWQS-BBQ', :tempId => '9876'
        @person.spouse_assertions.first.tempId.should eql('9876')
      end
    end
  end
  
end