module Org::Familysearch::Ws::Familytree::V2::Schema
  
  class RelationshipAssertions
    # ====Params
    # * <tt>options</tt> - :type ('Lineage' or valid CharacteristicType), :lineage => 'Biological', etc.
    def add_characteristic(options)
      self.characteristics ||= []
      characteristic = CharacteristicAssertion.new
      characteristic.add_value(options)
      self.characteristics << characteristic
    end
    
    # ====Params
    # * <tt>options</tt> - Accepts the following options
    # ** :type - 'Marriage', etc. REQUIRED
    # ** :date - 'Utah, United States' (optional)
    # ** :place - '16 Nov 1987' (optional)
    def add_event(options)
      self.events ||= []
      event = EventAssertion.new
      event.add_value(options)
      self.events << event
    end
    
    # ====Params
    # * <tt>options</tt> - Accepts the following options
    # ** :type - 'Sealing_to_Spouse', etc. REQUIRED
    # ** :date - 'Utah, United States' (optional)
    # ** :place - '16 Nov 1987' (optional)
    # ** :temple - 'SLAKE'
    def add_ordinance(options)
      self.ordinances ||= []
      ordinance = OrdinanceAssertion.new
      ordinance.add_value(options)
      self.ordinances << ordinance
    end
    
    def add_exists
      self.exists ||= []
      exist = ExistsAssertion.new
      exist.add_value
      self.exists << exist
    end
  end
  
  class Relationship
    def add_lineage_characteristic(lineage)
      add_assertions!
      self.assertions.add_characteristic(:type => 'Lineage', :lineage => lineage)
    end
    
    def add_exists
      add_assertions!
      self.assertions.add_exists
    end
    
    # ====Params
    # * <tt>event_hash</tt> - Accepts the following options
    # ** :type - 'Marriage', etc. REQUIRED
    # ** :date - 'Utah, United States' (optional)
    # ** :place - '16 Nov 1987' (optional)
    def add_event(event_hash)
      add_assertions!
      self.assertions.add_event(event_hash)
    end
    
    # ====Params
    # * <tt>ordinance_hash</tt> - Accepts the following options
    # ** :type - 'Sealing_to_Spouse', etc. REQUIRED
    # ** :date - 'Utah, United States' (optional)
    # ** :place - '16 Nov 1987' (optional)
    # ** :temple - 'SLAKE'
    def add_ordinance(ordinance_hash)
      add_assertions!
      self.assertions.add_ordinance(ordinance_hash)
    end
    
    private
    def add_assertions!
      self.assertions ||= RelationshipAssertions.new
    end
  end
  
  class FamilyReference
    def select_spouse(spouse_id)
      add_parents!
      self.action = 'Select'
      parent = PersonReference.new
      parent.id = spouse_id
      self.parents << parent
    end
    
    private
    def add_parents!
      self.parents ||= []
    end
  end
  
  class ParentsReference
    def select_parent(parent_id, gender)
      add_parents!
      self.action = 'Select'
      parent = PersonReference.new
      parent.gender = gender
      parent.id = parent_id
      self.parents << parent
    end
    
    private
    def add_parents!
      self.parents ||= []
    end
  end
  
  class PersonRelationships
    def initialize
      @parents = []
      @spouses = []
      @children = []
    end
    
    # ====Params
    # * <tt>options</tt> - requires the following: 
    # ** :type - 'parent', 'child', 'spouse'
    # ** :with - ID of the person with whom you are making the relationship
    # ** :lineage (optional) - 'Biological', 'Adoptive', etc.
    # ** :event - a hash with values {:type => 'Marriage', :date => '15 Nov 2007', :place => 'Utah, United States'}
    # ** :ordinance - a hash with values {:date => '15 Nov 2007', :temple => 'SLAKE', :place => 'Utah, United States', :type => "Sealing_to_Spouse"}
    def add_relationship(options)
      relationship = self.get_relationships_of_type(options[:type]).find{|r|r.id == options[:with] || r.requestedId == options[:with]}
      if relationship.nil?
        relationship = Relationship.new
        relationship.id = options[:with]
      end
      if options[:lineage]
        relationship.add_lineage_characteristic(options[:lineage]) if options[:lineage]
      else
        relationship.add_exists
      end
      if options[:event]
        relationship.add_event(options[:event])
      end
      if options[:ordinance]
        relationship.add_ordinance(options[:ordinance])
      end
      s_command = set_command(options[:type])
      self.send(s_command.to_sym,[relationship])
    end
    
    # ====Params
    # * type - should be 'child', 'spouse', or 'parent'
    def get_relationships_of_type(type)
      g_command = get_command(type)
      relationships = self.send(g_command.to_sym)
    end
    
    # Overriding the Enunciate code because of a bug (parents, spouses, and children were not pluralized)
    # the json hash for this PersonRelationships
    def to_jaxb_json_hash
      _h = {}
      if !parents.nil?
        _ha = Array.new
        parents.each { | _item | _ha.push _item.to_jaxb_json_hash }
        _h['parents'] = _ha
      end
      if !spouses.nil?
        _ha = Array.new
        spouses.each { | _item | _ha.push _item.to_jaxb_json_hash }
        _h['spouses'] = _ha
      end
      if !children.nil?
        _ha = Array.new
        children.each { | _item | _ha.push _item.to_jaxb_json_hash }
        _h['children'] = _ha
      end
      return _h
    end
    
    # Overriding the Enunciate code because of a bug
    #initializes this PersonRelationships with a json hash
    def init_jaxb_json_hash(_o)
      if !_o['parents'].nil?
        @parents = Array.new
        _oa = _o['parents']
        _oa.each { | _item | @parents.push Org::Familysearch::Ws::Familytree::V2::Schema::Relationship.from_json(_item) }
      end
      if !_o['spouses'].nil?
        @spouses = Array.new
        _oa = _o['spouses']
        _oa.each { | _item | @spouses.push Org::Familysearch::Ws::Familytree::V2::Schema::Relationship.from_json(_item) }
      end
      if !_o['children'].nil?
        @children = Array.new
        _oa = _o['children']
        _oa.each { | _item | @children.push Org::Familysearch::Ws::Familytree::V2::Schema::Relationship.from_json(_item) }
      end
    end
    
    private
    def get_command(type)
      (type.to_s == 'child') ? 'children' : "#{type}s"
    end
     
    def set_command(type)
      get_command(type)+"="
    end    
  end
  
end