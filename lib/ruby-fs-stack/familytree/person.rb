module Org::Familysearch::Ws::Familytree::V2::Schema
  
  class PersonAssertions
    def add_gender(value)
      self.genders ||= []
      g = GenderAssertion.new
      g.add_value(value)
      self.genders << g
    end
    
    def add_name(value)
      self.names ||= []
      n = NameAssertion.new
      n.add_value(value)
      self.names << n
    end
    
    def select_name(value_id)
      self.names ||= []
      n = NameAssertion.new
      n.select(value_id)
      self.names << n
    end
        
    def add_event(options)
      self.events ||= []
      e = EventAssertion.new
      e.add_value(options)
      self.events << e
    end
    
    def select_event_summary(type,value_id)
      self.events ||= []
      e = EventAssertion.new
      e.select(type,value_id)
      self.events << e
    end
    
    def add_ordinance(options)
      self.ordinances ||= []
      o = OrdinanceAssertion.new
      o.add_value(options)
      self.ordinances << o
    end
    
  end
  
  class Person
    
    def full_names
      if assertions && assertions.names
        return assertions.names.collect do |name|
          (name.value.forms[0].fullText.nil?) ? name.value.forms[0].buildFullText : name.value.forms[0].fullText
        end
      else
        []
      end
    end
    
    def full_name
      self.full_names.first
    end
    
    def surnames
      if assertions && assertions.names
        names =  assertions.names.collect do |name|
          name.value.forms[0].surname
        end
        return names.reject{|n|n.nil?}
      else
        []
      end
    end
    
    def surname
      surnames.first
    end
    
    def gender
      if assertions && assertions.genders && assertions.genders[0] && assertions.genders[0].value
        assertions.genders[0].value.type
      else
        nil
      end
    end
    
    # Convenience method for adding the gender.
    #
    # ====Params
    # <tt>value</tt> - 'Male' or 'Female'
    def add_gender(value)
      add_assertions!
      assertions.add_gender(value)
    end
    
    # Convenience method for adding a name. It fills in the necessary
    # structure underneath to create the name.
    # 
    # ====Params
    # <tt>value</tt> - the name to be added
    # 
    # ====Example
    # 
    #   person.add_name 'Parker Felch' # Sets the fullText to "Parker Felch"
    #   person.add_name 'Parker Jones /Felch/' # Does not set the fullText, but sets the name pieces.
    def add_name(value)
      add_assertions!
      assertions.add_name(value)
    end
    
    # Select the name for the summary view. This should be called on a Person record that
    # contains a person id and version.
    # 
    # ====Params
    # <tt>value_id</tt> - the value id of a name assertion that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_name_summary('1000134')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_name_summary(value_id)
      add_assertions!
      assertions.select_name(value_id)
    end
    
    def births
      select_events('Birth')
    end
    
    # It should return the selected birth assertion unless it is
    # not set in which case it will return the first
    def birth
      birth = births.find{|b|!b.selected.nil?}
      birth ||= births[0]
      birth
    end
    
    def deaths
      select_events('Death')
    end
    
    # It should return the selected death assertion unless it is
    # not set in which case it will return the first
    def death
      death = deaths.find{|b|!b.selected.nil?}
      death ||= deaths[0]
      death
    end
    
    # This should only be called on a person containing relationships
    def marriages(for_person)
      select_spouse_events('Marriage',for_person)
    end
    
    # This should only be called on a person containing relationships
    def divorces(for_person)
      select_spouse_events('Divorce',for_person)
    end
    
    # Add an event with type of Birth
    #
    # ====Params
    # * <tt>options</tt> - accepts a :date and :place option
    # 
    # ====Example
    #
    #   person.add_birth :date => '12 Aug 1902', :place => 'United States'
    def add_birth(options)
      add_assertions!
      options[:type] = 'Birth'
      assertions.add_event(options)
    end
    
    # Select the birth for the summary view. This should be called on a Person record that
    # contains a person id and version.
    # 
    # ====Params
    # <tt>value_id</tt> - the value id of a birth assertion that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_birth_summary('1000134')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_birth_summary(value_id)
      add_assertions!
      assertions.select_event_summary('Birth',value_id)
    end
        
    # Add an event with type of Birth
    #
    # ====Params
    # * <tt>options</tt> - accepts a :date and :place option
    # 
    # ====Example
    #
    #   person.add_birth :date => '12 Aug 1902', :place => 'United States'
    def add_death(options)
      add_assertions!
      options[:type] = 'Death'
      assertions.add_event(options)
    end
    
    # Select the death for the summary view. This should be called on a Person record that
    # contains a person id and version.
    # 
    # ====Params
    # <tt>value_id</tt> - the value id of a death assertion that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_death_summary('1000134')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_death_summary(value_id)
      add_assertions!
      assertions.select_event_summary('Death',value_id)
    end
    
    # Select the mother for the summary view. This should be called on a Person record that
    # contains a person id and version. 
    # 
    # Make sure you set both the mother and father before saving the person. Otherwise you will 
    # set a single parent as the summary.
    # 
    # ====Params
    # <tt>person_id</tt> - the person id of the mother that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_mother_summary('KWQS-BBQ')
    #   person.select_father_summary('KWQS-BBT')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_mother_summary(person_id)
      add_parents!
      couple = parents[0] || ParentsReference.new
      couple.select_parent(person_id,'Female')
      parents[0] = couple 
    end
    
    # Select the father for the summary view. This should be called on a Person record that
    # contains a person id and version. 
    # 
    # Make sure you set both the mother and father before saving the person. Otherwise you will 
    # set a single parent as the summary.
    # 
    # ====Params
    # <tt>person_id</tt> - the person id of the father that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_father_summary('KWQS-BBQ')
    #   person.select_mother_summary('KWQS-BBT')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_father_summary(person_id)
      add_parents!
      couple = parents[0] || ParentsReference.new
      couple.select_parent(person_id,'Male')
      parents[0] = couple 
    end
    
    # Select the spouse for the summary view. This should be called on a Person record that
    # contains a person id and version. 
    # 
    # ====Params
    # <tt>person_id</tt> - the person id of the spouse that you would like to set as the summary
    # 
    # ===Example
    #   person = com.familytree_v2.person 'KWQS-BBR', :names => 'none', :genders => 'none', :events => 'none'
    #   person.select_spouse_summary('KWQS-BBQ')
    #   com.familytree_v2.save_person person
    # 
    # This is the recommended approach, to start with a "Version" person (no names, genders, or events)
    def select_spouse_summary(person_id)
      add_families!
      family = FamilyReference.new
      family.select_spouse(person_id)
      families << family 
    end
    
    def baptisms
      select_ordinances('Baptism')
    end
    
    def confirmations
      select_ordinances('Confirmation')
    end
    
    def initiatories
      select_ordinances('Initiatory')
    end
    
    def endowments
      select_ordinances('Endowment')
    end
    
    def sealing_to_parents
      select_ordinances(OrdinanceType::Sealing_to_Parents)
    end
    
    def sealing_to_spouses(id)
      select_relationship_ordinances(:relationship_type => 'spouse', :id => id, :type => OrdinanceType::Sealing_to_Spouse)
    end
    
    # Add a baptism ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date, :place, and :temple option
    #
    # ====Example
    #
    #   person.add_baptism :date => '14 Aug 2009', :temple => 'SGEOR', :place => 'Salt Lake City, Utah'
    def add_baptism(options)
      add_assertions!
      options[:type] = 'Baptism'
      assertions.add_ordinance(options)
    end
    
    # Add a confirmation ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date, :place, and :temple option
    #
    # ====Example
    #
    #   person.add_confirmation :date => '14 Aug 2009', :temple => 'SGEOR', :place => 'Salt Lake City, Utah'
    def add_confirmation(options)
      add_assertions!
      options[:type] = 'Confirmation'
      assertions.add_ordinance(options)
    end
    
    # Add a initiatory ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date, :place, and :temple option
    #
    # ====Example
    #
    #   person.add_initiatory :date => '14 Aug 2009', :temple => 'SGEOR', :place => 'Salt Lake City, Utah'
    def add_initiatory(options)
      add_assertions!
      options[:type] = 'Initiatory'
      assertions.add_ordinance(options)
    end
    
    # Add a endowment ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date, :place, and :temple option
    #
    # ====Example
    #
    #   person.add_endowment :date => '14 Aug 2009', :temple => 'SGEOR', :place => 'Salt Lake City, Utah'
    def add_endowment(options)
      add_assertions!
      options[:type] = 'Endowment'
      assertions.add_ordinance(options)
    end
    
    # Add a sealing to parents ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date, :place, :temple, :mother, and :father option
    #
    # ====Example
    #
    #   person.add_sealing_to_parents :date => '14 Aug 2009', :temple => 'SGEOR', :place => 'Salt Lake City, Utah'
    def add_sealing_to_parents(options)
      raise ArgumentError, ":mother option is required" if options[:mother].nil?
      raise ArgumentError, ":father option is required" if options[:father].nil?
      add_assertions!
      options[:type] = OrdinanceType::Sealing_to_Parents
      assertions.add_ordinance(options)
    end
    
    # This method should really only be called from FamilytreeV2::Communicator#write_relationships
    # 
    # ====Params
    # * <tt>options</tt> - requires the following: 
    #   * :type - 'parent', 'child', 'spouse'
    #   * :with - ID of the person with whom you are making the relationship
    #   * :lineage (optional) - 'Biological', 'Adoptive', etc.
    #   * :event - a hash with values {:type => 'Marriage', :date => '15 Nov 2007', :place => 'Utah, United States'}
    def create_relationship(options)
      raise ArgumentError, ":type option is required" if options[:type].nil?
      raise ArgumentError, ":with option is required" if options[:with].nil?
      add_relationships!
      self.relationships.add_relationship(options)
    end
    
    # This method should only be called from FamilytreeV2::Communicator#combine
    # 
    # ====Params
    # * <tt>persons</tt> - an array of person objects. All persons must have an id and version
    def create_combine(persons)
      self.personas = Org::Familysearch::Ws::Familytree::V2::Schema::PersonPersonas.new
      self.personas.personas = persons.map do |person|
        persona = Org::Familysearch::Ws::Familytree::V2::Schema::PersonPersona.new
        persona.id = person.id
        persona.version = person.version
        persona
      end
    end
    
    def father_id
      parent_id('Male')
    end
    
    def mother_id
      parent_id('Female')
    end
    
    def spouse_id
      if families && families[0] && families[0].parents
        spouse_ref = families[0].parents.find{|p|p.id != self.id}
        spouse_ref.id if spouse_ref
      end
    end
  
    private
    
    def parent_id(gender)
      if parents && parents[0]
        parent_ref = parents[0].parents.find{|p|p.gender == gender}
        parent_ref.id if parent_ref
      end
    end
    
    def add_parents!
      self.parents ||= []
    end
    
    def add_families!
      self.families ||= []
    end
    
    def add_relationships!
      self.relationships ||= PersonRelationships.new
    end
    
    def add_assertions!
      if assertions.nil?
        self.assertions = PersonAssertions.new
      end
    end
    
    def select_events(type)
      if assertions && assertions.events
        assertions.events.select{|e| e.value.type == type}
      else
        []
      end
    end
    
    def select_spouse_events(type,for_person)
      spouse = relationships.spouses.find{|s|s.requestedId=for_person}
      if spouse.assertions && spouse.assertions.events
        spouse.assertions.events.select{|e| e.value.type == type}
      else
        []
      end
    end
    
    def select_ordinances(type)
      if assertions && assertions.ordinances
        assertions.ordinances.select{|e| e.value.type == type}
      else
        []
      end
    end
    
    # only ordinance type is Sealing_to_Spouse
    def select_relationship_ordinances(options)
      raise ArgumentError, ":id required" if options[:id].nil?
      if self.relationships
        spouse_relationship = self.relationships.spouses.find{|s|s.id == options[:id]}
        if spouse_relationship && spouse_relationship.assertions && spouse_relationship.assertions.ordinances
          spouse_relationship.assertions.ordinances
        else
          []
        end
      end
    end
  
  end
end