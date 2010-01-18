require File.dirname(__FILE__) + '/../spec_helper'
require 'ruby-fs-stack/familytree'


describe Org::Familysearch::Ws::Familytree::V2::Schema::Person do
  FamTreeV2 = Org::Familysearch::Ws::Familytree::V2::Schema
  
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
        
        it "should return a name pieced together from pieces" do
          @person.add_name("Parker James /Felch/")
          names = @person.full_names
          names[3].should == "Parker James Felch"
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
        
        def add_blank_form
          nameAssertion = FamTreeV2::NameAssertion.new
          nameAssertion.value = FamTreeV2::NameValue.new
          nameAssertion.value.forms = [FamTreeV2::NameForm.new]
          @person.assertions.names[0] = nameAssertion
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
        
        it "should return [] if a only a blank nameform" do
          add_assertions
          add_names_array
          add_blank_form
          @person.full_names.should == ['']
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
        @person.births[1].selected = Org::Familysearch::Ws::Familytree::V2::Schema::ValueSelection.new
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
    
    describe "deaths" do
      describe "for persons with at least one death event" do
        before(:each) do
          @person = parse_person
        end
        
        it "should return an array of the death events" do
          deaths = @person.deaths
          deaths.should be_a_kind_of(Array)
          deaths.each do |e|
            e.value.type.should == 'Death'
          end
        end
      end
      
      describe "for persons without a death" do
        def add_events_array
          @person.assertions.events = []
        end
        
        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.deaths.should == []
        end

        it "should return [] if no events" do
          add_assertions
          @person.deaths.should == []
        end

        it "should return [] if no events of type Death are found" do
          add_assertions
          add_events_array
          @person.deaths.should == []
        end
        
      end
      
    end
    
    describe "death" do
      
      before(:each) do
        @person = parse_person
      end
      
      it "should return the 'selected' death if an assertion is selected" do
        @person.deaths[1].selected = Org::Familysearch::Ws::Familytree::V2::Schema::ValueSelection.new
        @person.death.should == @person.deaths[1]
      end
      
      it "should return the first death if no assertions are selected" do
        @person.death.should == @person.deaths[0]
      end
      
      it "should return nil if no deaths" do
        @person = parse_person('KJ86-3VD_version.js')
        @person.death.should == nil
      end
    end
    
    describe "marriages" do
      before(:each) do
        @person = parse_person('spouse_read.js')
      end
      
      it "should accept a spouse id." do
        @person.marriages('KW3B-VVY')
      end
      
      it "should return an array of marriage elements" do
        marriages = @person.marriages('KW3B-VVY')
        marriages.should be_instance_of(Array)
      end
      
      it "should return all marriages" do
        marriages = @person.marriages('KW3B-VVY')
        marriages[0].date.normalized.should == '1853'
        marriages[1].date.normalized.should == 'Aug 1853'
      end
      
      describe "checking for cases where there are no assertsions, events, or marriages" do
        before(:each) do
          @spouse = @person.relationships.spouses.find{|s|s.requestedId=='KW3B-VVY'}
        end
        
        it "should return [] if no assertions" do
          @spouse.assertions = nil
          @person.marriages('KW3B-VVY').should == []
        end
        
        it "should return [] if no events" do
          @spouse.assertions.events = nil
          @person.marriages('KW3B-VVY').should == []
        end
        
      end
    end
    
    describe "selecting summaries" do
      before(:each) do
        @person = parse_person('KJ86-3VD_version.js')
      end
      
      describe "select_name_summary" do
        
        it "should accept a value ID" do
          @person.select_name_summary('10001')
        end
        
        it "should add a name assertion with action, value, and id" do
          @person.select_name_summary('10001')
          @person.assertions.names[0].value.id.should == '10001'
          @person.assertions.names[0].action.should == 'Select'
        end
        
      end
      
      describe "select_birth_summary" do
        
        it "should accept a value ID" do
          @person.select_birth_summary('10001')
        end
        
        it "should add a name assertion with action, value, and id" do
          @person.select_birth_summary('10001')
          @person.births[0].value.id.should == '10001'
          @person.births[0].action.should == 'Select'
        end
        
      end
      
      describe "select_death_summary" do
        
        it "should accept a value ID" do
          @person.select_death_summary('10001')
        end
        
        it "should add a name assertion with action, value, and id" do
          @person.select_death_summary('10002')
          @person.deaths[0].value.id.should == '10002'
          @person.deaths[0].action.should == 'Select'
        end
        
      end
      
      describe "select_mother_summary" do
        
        it "should accept a parent ID" do
          @person.select_mother_summary('KWQS-BBR')
        end
        
        it "should set the parents with given mother as a selected parent" do
          @person.select_mother_summary('KWQS-BBR')
          @person.parents[0].parents[0].id.should == 'KWQS-BBR'
          @person.parents[0].parents[0].gender.should == 'Female'
          @person.parents[0].action.should == 'Select'
        end
        
      end
      
      describe "select_father_summary" do
        
        it "should accept a parent ID" do
          @person.select_father_summary('KWQS-BBQ')
        end
        
        it "should set the parents with given mother as a selected parent" do
          @person.select_father_summary('KWQS-BBQ')
          @person.parents[0].parents[0].id.should == 'KWQS-BBQ'
          @person.parents[0].parents[0].gender.should == 'Male'
          @person.parents[0].action.should == 'Select'
        end
        
      end
      
      describe "select_father_summary and select_mother_summary" do
        
        it "should accept a parent ID" do
          @person.select_mother_summary('KWQS-BBR')
          @person.select_father_summary('KWQS-BBQ')
        end
        
        it "should set the parents with given mother as a selected parent" do
          @person.select_mother_summary('KWQS-BBR')
          @person.select_father_summary('KWQS-BBQ')
          @person.parents[0].parents[0].id.should == 'KWQS-BBR'
          @person.parents[0].parents[1].id.should == 'KWQS-BBQ'
          @person.parents[0].parents[0].gender.should == 'Female'
          @person.parents[0].parents[1].gender.should == 'Male'
          @person.parents[0].action.should == 'Select'
          @person.parents.size.should == 1
        end
        
      end
      
      describe "select_spouse_summary" do
        
        it "should accept a spouse's ID" do
          @person.select_spouse_summary('KWQS-BBB')
        end
        
        it "should set the families with given spouse as a selected parent" do
          @person.select_spouse_summary('KWQS-BBB')
          @person.families[0].parents[0].id.should == 'KWQS-BBB'
          @person.families[0].action.should == 'Select'
        end
        
      end
      
    end
    
    describe "baptisms" do
      describe "for persons with at least one baptism" do
        before(:each) do
          @person = parse_person
        end

        it "should return an array of the baptism" do
          baptisms = @person.baptisms
          baptisms.should be_a_kind_of(Array)
          baptisms.each do |e|
            e.value.type.should == 'Baptism'
          end
        end
      end

      describe "for persons without a baptism" do
        def add_ordinances_array
          @person.assertions.ordinances = []
        end

        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.baptisms.should == []
        end

        it "should return [] if no ordinances" do
          add_assertions
          @person.baptisms.should == []
        end

        it "should return [] if no ordinances of type Baptism are found" do
          add_assertions
          add_ordinances_array
          @person.baptisms.should == []
        end

      end

    end

    describe "confirmations" do
      describe "for persons with at least one confirmation" do
        before(:each) do
          @person = parse_person
        end

        it "should return an array of the confirmation" do
          confirmations = @person.confirmations
          confirmations.should be_a_kind_of(Array)
          confirmations.each do |e|
            e.value.type.should == 'Confirmation'
          end
        end
      end

      describe "for persons without a confirmation" do
        def add_ordinances_array
          @person.assertions.ordinances = []
        end

        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.confirmations.should == []
        end

        it "should return [] if no ordinances" do
          add_assertions
          @person.confirmations.should == []
        end

        it "should return [] if no ordinances of type Confirmation are found" do
          add_assertions
          add_ordinances_array
          @person.confirmations.should == []
        end

      end

    end

    describe "initiatories" do
      describe "for persons with at least one confirmation" do
        before(:each) do
          @person = parse_person
        end

        it "should return an array of the confirmation" do
          initiatories = @person.initiatories
          initiatories.should be_a_kind_of(Array)
          initiatories.each do |e|
            e.value.type.should == 'Initiatory'
          end
        end
      end

      describe "for persons without a confirmation" do
        def add_ordinances_array
          @person.assertions.ordinances = []
        end

        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.initiatories.should == []
        end

        it "should return [] if no ordinances" do
          add_assertions
          @person.initiatories.should == []
        end

        it "should return [] if no ordinances of type Initiatory are found" do
          add_assertions
          add_ordinances_array
          @person.initiatories.should == []
        end

      end

    end

    describe "endowments" do
      describe "for persons with at least one confirmation" do
        before(:each) do
          @person = parse_person
        end

        it "should return an array of the confirmation" do
          endowments = @person.endowments
          endowments.should be_a_kind_of(Array)
          endowments.each do |e|
            e.value.type.should == 'Endowment'
          end
        end
      end

      describe "for persons without a confirmation" do
        def add_ordinances_array
          @person.assertions.ordinances = []
        end

        before(:each) do
          @person = parse_person('KJ86-3VD_version.js')
        end

        it "should return [] if no assertions" do
          @person.endowments.should == []
        end

        it "should return [] if no ordinances" do
          add_assertions
          @person.endowments.should == []
        end

        it "should return [] if no ordinances of type Endowment are found" do
          add_assertions
          add_ordinances_array
          @person.endowments.should == []
        end

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
      @person = new_person
      @person.add_gender "Female"
      @person.gender.should == 'Female'
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
      place = "Tuscarawas, Ohio, United States"
      date = "15 Jan 1844"
      @person.add_birth :place => place, :date => date
      @person.birth.value.date.original.should eql(date)
      @person.birth.value.place.original.should eql(place)
    end

    it "should provide easy access methods for assigning death" do
      place = "Tuscarawas, Ohio, United States"
      date = "16 Jan 1855"
      @person.add_death :place => place, :date => date
      @person.death.value.place.original.should eql(place)
      @person.death.value.date.original.should eql("16 Jan 1855")
    end
    
    it "should provide easy access methods for writing LDS ordinances" do
      date = "16 Jan 2009"
      temple = "SGEOR"
      place = "St. George, Utah, United States"
      
      #baptisms
      @person.add_baptism :date => date, :temple => temple, :place => place
      @person.baptisms.size.should == 1
      @person.baptisms.first.value.date.original.should == date
      @person.baptisms.first.value.temple.should == temple
      @person.baptisms.first.value.place.original.should == place
      
      #confirmations
      @person.add_confirmation :date => date, :temple => temple, :place => place
      @person.confirmations.size.should == 1
      @person.confirmations.first.value.date.original.should == date
      @person.confirmations.first.value.temple.should == temple
      @person.confirmations.first.value.place.original.should == place
      
      #initiatory
      @person.add_initiatory :date => date, :temple => temple, :place => place
      @person.initiatories.size.should == 1
      @person.initiatories.first.value.date.original.should == date
      @person.initiatories.first.value.temple.should == temple
      @person.initiatories.first.value.place.original.should == place
      
      #endowment
      @person.add_endowment :date => date, :temple => temple, :place => place
      @person.endowments.size.should == 1
      @person.endowments.first.value.date.original.should == date
      @person.endowments.first.value.temple.should == temple
      @person.endowments.first.value.place.original.should == place
      
      #sealing_to_parents
      @person.add_sealing_to_parents :date => date, :temple => temple, :place => place, :mother => 'KWQS-BBR', :father => 'KWQS-BBQ'
      @person.sealing_to_parents.size.should == 1
      @person.sealing_to_parents.first.value.date.original.should == date
      @person.sealing_to_parents.first.value.temple.should == temple
      @person.sealing_to_parents.first.value.place.original.should == place
      @person.sealing_to_parents.first.value.parents.size.should == 2
      @person.sealing_to_parents.first.value.parents.find{|p|p.gender == 'Male'}.id.should == 'KWQS-BBQ'
      @person.sealing_to_parents.first.value.parents.find{|p|p.gender == 'Female'}.id.should == 'KWQS-BBR'
      @person.sealing_to_parents.first.value.type.should == "Sealing to Parents"
      
      #sealing_to_spouse
      @person.create_relationship :type => 'spouse', :with => 'KWQS-BBR', :ordinance => {:date => date, :temple => temple, :place => place, :type => "Sealing to Spouse"}
      @person.sealing_to_spouses('KWQS-BBR').size.should == 1
      sts = @person.sealing_to_spouses('KWQS-BBR')
      sts.first.value.type.should == "Sealing to Spouse"
      sts.first.value.date.original.should == date
      sts.first.value.temple.should == temple
      sts.first.value.place.original.should == place
    end

    it "should be able to build a relationship write request for a parent relationship" do
      @person.create_relationship :type => 'parent', :with => 'KWQS-BBR', :lineage => 'Biological'
      @person.relationships.parents.size.should == 1
      @person.relationships.parents[0].id.should == 'KWQS-BBR'
      @person.relationships.parents[0].assertions.characteristics[0].value.lineage.should == 'Biological'
      @person.relationships.parents[0].assertions.characteristics[0].value.type.should == 'Lineage'
    end
    
    it "should be able to build a relationship write request for a spouse relationship" do
      @person.create_relationship :type => 'spouse', :with => 'KWQS-BBZ'
      @person.relationships.spouses.size.should == 1
      @person.relationships.spouses[0].id.should == 'KWQS-BBZ'
      @person.relationships.spouses[0].assertions.exists[0].value.should be_instance_of(Org::Familysearch::Ws::Familytree::V2::Schema::ExistsValue)
    end
    
    it "should be able to build a relationship write request for a spouse relationship" do
      @person.create_relationship :type => 'spouse', :with => 'KWQS-BBZ', :event => {:type => 'Marriage',:place =>"Utah, United States", :date => '15 Nov 2007'}
      @person.relationships.spouses.size.should == 1
      @person.relationships.spouses[0].id.should == 'KWQS-BBZ'
      @person.relationships.spouses[0].assertions.events[0].value.type.should == 'Marriage'
      @person.relationships.spouses[0].assertions.events[0].value.date.original.should == '15 Nov 2007'
      @person.relationships.spouses[0].assertions.events[0].value.place.original.should == 'Utah, United States'
      @person.relationships.spouses[0].assertions.exists[0].value.should be_instance_of(Org::Familysearch::Ws::Familytree::V2::Schema::ExistsValue)
      @person.create_relationship :type => 'spouse', :with => 'KWQS-BBZ', :event => {:type => 'Marriage',:place =>"Utah, United States", :date => '15 Nov 2007'}
      @person.relationships.spouses[0].assertions.events.size.should == 2
    end
    
  end
  
  describe "create_combine" do
    def new_combine_person(id,version)
      person = new_person
      person.id = id
      person.version = version
      person
    end
    
    before(:each) do
      @person = new_person
      @persons = [new_combine_person('KWQS-BBR','1'),new_combine_person('KWQS-BBQ','2'),new_combine_person('KWQS-BBZ','3')]
    end
    
    it "should accept an array of person objects" do
      @person.create_combine(@persons)
      @person.personas.personas[0].id.should == 'KWQS-BBR'
      @person.personas.personas[0].version.should == '1'
      @person.personas.personas[1].id.should == 'KWQS-BBQ'
      @person.personas.personas[1].version.should == '2'
      @person.personas.personas[2].id.should == 'KWQS-BBZ'
      @person.personas.personas[2].version.should == '3'
    end
    
  end
  
end