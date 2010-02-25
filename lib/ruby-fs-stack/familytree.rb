require 'rubygems'
require 'ruby-fs-stack/fs_communicator'
require 'ruby-fs-stack/fs_utils'

# Including more than one enunciate library raises a warning of
# already initialized constant.
require 'ruby-fs-stack/warning_suppressor'
with_warnings_suppressed do
  require 'ruby-fs-stack/enunciate/familytree'
end


module FamilytreeV2
  
  # This method gets mixed into the FsCommunicator so that
  # you can make calls on the familytree_v2 module
  def familytree_v2
    @familytree_v2_com ||= Communicator.new self # self at this point refers to the FsCommunicator instance
  end
  
  class Communicator
    Base = '/familytree/v2/'
    
    # ===params
    # fs_communicator: FsCommunicator instance
    def initialize(fs_communicator)
      @fs_communicator = fs_communicator
    end
    
    # ===params
    # <tt>id_or_ids</tt> should be a string of the persons identifier. For the 'me' person, use :me or 'me'. Can also accept an array of ID strings.
    # <tt>options</tt> accepts a hash of parameters as documented by the API.
    # For full parameter documentation, see DevNet[https://devnet.familysearch.org/docs/api-manual-reference-system/familytree-v2/r_api_family_tree_person_read_v2.html]
    #
    # ===Example
    #   # communicator is an authenticated FsCommunicator object
    #   # Request a person with no assertions, only the version.
    #   p = communicator.familytree_v2.person :me, :names => 'none', :genders => 'none', :events => 'none'
    #   
    #   p.version # => '90194378772'
    #   p.id # => 'KW3B-NNM'
    def person(id_or_ids, options = {})
      if id_or_ids.kind_of? Array
        multiple_ids = true
        url = Base + 'person/' + id_or_ids.join(',')
      else
        multiple_ids = false
        id = id_or_ids.to_s
        if id == 'me'
          url = Base + 'person'
        else
          url = Base + 'person/' + id
        end
      end
      url += add_querystring(options)
      response = @fs_communicator.get(url)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      if multiple_ids
        return familytree.persons
      else
        person = familytree.persons.find{|p| p.requestedId == id }
        person ||= familytree.persons.first if id == 'me'
        return person
      end
    end
    
    def save_person(person)
      if person.id.nil?
        url = Base + 'person'
      else
        url = Base + 'person/' + person.id
      end
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
      familytree.persons = [person]
      response = @fs_communicator.post(url,familytree.to_json)
      res_familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      person = res_familytree.persons.first
      return person
    end
    
    # ====Params
    # <tt>search_params</tt> - A hash of search parameters matching API doc
    def search(search_params)
      url = Base + 'search'
      url += add_querystring(search_params)
      response = @fs_communicator.get(url)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      # require 'pp'
      # pp familytree
      familytree.searches[0]
    end
    
    # ====Params
    # <tt>id_or_hash</tt> - Either an ID or a hash of match parameters matching API doc
    # <tt>hash</tt> - if the first parameter is an ID, then this will contain the hash
    # of match parameters.
    def match(id_or_hash, hash={})
      url = Base + 'match'
      if id_or_hash.kind_of? String
        id = id_or_hash
        url += "/#{id}"
        params_hash = hash
      elsif id_or_hash.kind_of? Hash
        id = nil
        params_hash = id_or_hash
      else
        raise ArgumentError, "first parameter must be a kind of String or Hash"
      end
      url += add_querystring(params_hash) #"?" + FsUtils.querystring_from_hash(params_hash) unless params_hash.empty?
      response = @fs_communicator.get(url)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      # require 'pp'
      # pp familytree
      familytree.matches[0]
    end
    
    # ====Params
    # * <tt>base_id</tt> - The root person for creating the relationship
    # * <tt>options</tt> - Should include either :parent, :spouse, or :child. :lineage and :event is optional
    #
    # :lineage can be set to the following values:
    # * 'Biological'
    # * 'Adoptive'
    # * 'Foster'
    # * 'Guardianship'
    # * 'Step'
    # * 'Other'
    # 
    # :event should be a hash with the following values
    # ** :type - "Marriage", etc. (REQUIRED)
    # ** :place - "Utah, United States" (optional)
    # ** :date - "Nov 2009"
    #
    # :ordinance should be a hash with the following values
    # ** :type - "Sealing_to_Spouse", etc. (REQUIRED)
    # ** :place - "Utah, United States" (optional)
    # ** :date - "Nov 2009"
    # ** :temple - 'SLAKE'
    #
    # If the :lineage is set, the parent-child relationships will be written via a characteristic.
    # Otherwise, an exists assertion will be created to just establish the relationship.
    # ====Example
    #
    #    communicator.familytree_v2.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBT', :lineage => 'Biological' 
    #    communicator.familytree_v2.write_relationship 'KWQS-BBQ', :parent => 'KWQS-BBT', :lineage => 'Adoptive'
    #    communicator.familytree_v2.write_relationship 'KWQS-BBQ', :spouse => 'KWRT-BBZ', :event => {:type => 'Marriage', :date => '15 Aug 1987', :place => 'Utah, United States'}
    def write_relationship(base_id,options)
      
      relationship_type = get_relationship_type(options)
      with_id = options[relationship_type.to_sym]
            
      url = "#{Base}person/#{base_id}/#{relationship_type}/#{with_id}"

      # Get the existing person/relationship or create a new person
      unless person = relationship(base_id,options.merge({:events => 'none'}))
        person = Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
        person.id = base_id
      end
      
      # Add the relationship to the person with all of the correct options
      r_options = {:type => relationship_type, :with => with_id}
      r_options[:event] = options[:event] if options[:event]
      r_options[:ordinance] = options[:ordinance] if options[:ordinance]
      r_options[:lineage] = options[:lineage] if options[:lineage]
      person.create_relationship r_options
      
      # Create the payload
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
      familytree.persons = [person]
      
      # Post the response and return the resulting person/relationship record from response
      response = @fs_communicator.post(url,familytree.to_json)
      res_familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      person = res_familytree.persons.first
      return person 
    end
    
    # ====Params
    # * <tt>base_id</tt> - The root person for creating the relationship
    # * <tt>options</tt> - Should include either :parent, :spouse, or :child. :lineage and :event is optional.
    #   Other Relationship Read parameters may be included in options such as :events => 'all', 
    #   :characteristics => 'all', etc.
    #
    # If the :lineage is set, the parent-child relationships will be written via a characteristic.
    # Otherwise, an exists assertion will be created to just establish the relationship.
    # ====Example
    #
    #    communicator.familytree_v2.relationship 'KWQS-BBQ', :parent => 'KWQS-BBT'
    #    communicator.familytree_v2.relationship 'KWQS-BBQ', :parent => 'KWQS-BBT'
    def relationship(base_id,options)
      begin
        r_type = get_relationship_type(options)
        with_id = options[r_type.to_sym]
        url = "#{Base}person/#{base_id}/#{r_type}/#{with_id}"
        options.reject!{|k,v| k.to_s == 'spouse'}
        url += add_querystring(options)
        res = @fs_communicator.get(url)
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(res.body)
        person = familytree.persons.find{|p|p.requestedId == base_id}
        return person
      rescue RubyFsStack::NotFound
        return nil
      end
    end
    
    # Writes a note attached to the value ID of the specific person or relationship.
    # 
    # ====Params
    # * <tt>options</tt> - Options for the note including the following:
    #   * <tt>:personId</tt> - the person ID if attaching to a person assertion.
    #   * <tt>:spouseIds</tt> - an Array of spouse IDs if creating a note attached to a spouse 
    #     relationship assertion.
    #   * <tt>:parentIds</tt> - an Array of parent IDs if creating a note attached to a parent 
    #     relationship assertion. If creating a note for a child-parent or parent-child 
    #     relationship, you will need only one parent ID in the array along with a :childId option.
    #   * <tt>:childId</tt> - a child ID.
    #   * <tt>:text</tt> - the text of the note (required).
    #   * <tt>:assertionId</tt> - the valueId of the assertion you are attaching this note to.
    # 
    def write_note(options)
      url = "#{Base}note"
      note = Org::Familysearch::Ws::Familytree::V2::Schema::Note.new
      note.build(options)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
      familytree.notes = [note]
      res = @fs_communicator.post(url,familytree.to_json)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(res.body)
      return familytree.notes.first
    end
    
    # Combines person into a new person
    #  
    # ====Params
    # * <tt>person_array</tt> - an array of person IDs.
    def combine(person_array)
      url = Base + 'person'
      version_persons = self.person person_array, :genders => 'none', :events => 'none', :names => 'none'
      combine_person = Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
      combine_person.create_combine(version_persons)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.new
      familytree.persons = [combine_person]
      res = @fs_communicator.post(url,familytree.to_json)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(res.body)
      return familytree.persons[0]
    end
    
    def pedigree(id_or_ids)
      if id_or_ids.kind_of? Array
        multiple_ids = true
        url = Base + 'pedigree/' + id_or_ids.join(',')
      else
        multiple_ids = false
        id = id_or_ids.to_s
        if id == 'me'
          url = Base + 'pedigree'
        else
          url = Base + 'pedigree/' + id
        end
      end
      # url += add_querystring(options)
      response = @fs_communicator.get(url)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      if multiple_ids
        return familytree.pedigrees
      else
        pedigree = familytree.pedigrees.find{|p| p.requestedId == id }
        pedigree ||= familytree.pedigrees.first if id == 'me'
        return pedigree
      end
    end
    
    private
    #options will either have a :parent, :child, or :spouse key. We need to find which one
    def get_relationship_type(options)
      keys = options.keys.collect{|k|k.to_s}
      key = keys.find{|k| ['parent','child','spouse'].include? k} 
      key
    end
    
    def add_querystring(options)
      params = options.reject{|k,v| ['parent','child','lineage','event'].include? k.to_s }
      (params.empty?) ? '' : "?" + FsUtils.querystring_from_hash(params)
    end
  end
  
end

# Mix in the module so that the fs_familytree_v1 can be called
class FsCommunicator
  include FamilytreeV2
end



module Org::Familysearch::Ws::Familytree::V2::Schema
  
  class GenderAssertion
    def add_value(value)
      self.value = GenderValue.new
      self.value.type = value
    end
  end
  
  class NameForm
    def set_name(name)
      split_pieces = name.match(/(.*)\/(.*)\//)
      # if there is a name like John Jacob /Felch/, split to name pieces, otherwise use fullText
      if split_pieces
        given_pieces = split_pieces[1]
        family_pieces = split_pieces[2]
        self.pieces = given_pieces.split(" ").collect do |piece|
          p = NamePiece.new
          p.type = "Given"
          p.postdelimiters = " "
          p.value = piece
          p
        end
        self.pieces = self.pieces + family_pieces.split(" ").collect do |piece|
          p = NamePiece.new
          p.type = "Family"
          p.predelimiters = ""
          p.value = piece
          p
        end
      else
        self.fullText = name
      end
    end
    
    def buildFullText
      if self.pieces.nil?
        return ''
      else
        self.pieces.collect{|piece| "#{piece.predelimiters}#{piece.value}#{piece.postdelimiters}"}.join('')
      end
    end
  end
  
  class NameValue
    def add_form(value)
      self.forms = []
      f = NameForm.new
      f.set_name(value)
      self.forms << f
    end
    
  end
  
  class NameAssertion
    def add_value(value)
      self.value = NameValue.new
      self.value.add_form(value)
    end
    
    def select(value_id)
      self.action = 'Select'
      self.value = AssertionValue.new
      self.value.id = value_id
    end
  end
  
  class EventValue
    def add_date(value)
      self.date = GenDate.new
      self.date.original = value
    end
    
    def add_place(value)
      self.place = Place.new
      self.place.original = value
    end
  end
  
  class EventAssertion
    # ====Params
    # * <tt>options</tt> - requires a :type option and accepts an (optional) :date and :place option
    # 
    # ====Example
    #
    #   person.add_birth :date => '12 Aug 1902', :place => 'United States'
    def add_value(options)
      raise ArgumentError, "missing option[:type]" if options[:type].nil?
      self.value = EventValue.new
      self.value.type = options[:type]
      self.value.add_date(options[:date]) if options[:date]
      self.value.add_place(options[:place]) if options[:place]
    end
    
    def select(type,value_id)
      self.value = EventValue.new
      self.value.id = value_id
      self.value.type = type
      self.action = 'Select'
    end
    
    # To make porting code from v1 to v2 easier, date will reference
    # value.date
    def date
      value.date
    end
    
    # To make porting code from v1 to v2 easier, date will reference
    # value.date
    def place
      value.place
    end
  end
  
  class OrdinanceType

    #  Born in Covenant -> Possibly needs to be changed to no underscores 
    # Born_in_Covenant = "Born_in_Covenant"
    
    # Override the incorrect constants in the enunciate library
    with_warnings_suppressed do
      #  Sealing to parents.
      Sealing_to_Parents = "Sealing to Parents"

      #  Sealing to spouse.
      Sealing_to_Spouse = "Sealing to Spouse"
    end
  end
  
  
  class OrdinanceValue
    
    def add_date(value)
      self.date = GenDate.new
      self.date.original = value
    end
    
    def add_place(value)
      self.place = Place.new
      self.place.original = value
    end
    
    def add_mother(mother_id)
      add_parent('Female',mother_id)
    end
    
    def add_father(father_id)
      add_parent('Male',father_id)
    end
    
    def add_parent(gender, id)
      add_parents!
      parent = PersonReference.new
      parent.id = id
      parent.gender = gender
      self.parents << parent
    end
    
    private
    def add_parents!
      self.parents ||= []
    end
    
  end
  
  class OrdinanceAssertion
    
    def add_value(options)
      raise ArgumentError, "missing option[:type]" if options[:type].nil?
      raise ArgumentError, "missing option[:place]" if options[:place].nil?
      self.value = OrdinanceValue.new
      self.value.type = options[:type]
      self.value.add_date(options[:date]) if options[:date]
      self.value.add_place(options[:place]) if options[:place]
      self.value.temple = options[:temple] if options[:temple]
      if options[:type] == OrdinanceType::Sealing_to_Parents
        self.value.add_mother(options[:mother])
        self.value.add_father(options[:father])
      end
    end
  end

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
  
  class CharacteristicAssertion
    # ====Params
    # * <tt>options</tt> - same as RelationshipAssertions#add_characteristic
    def add_value(options)
      self.value = CharacteristicValue.new
      self.value.type = options[:type]
      self.value.lineage = options[:lineage] if options[:lineage]
    end
  end
  
  class ExistsAssertion
    def add_value
      self.value = ExistsValue.new
    end
  end
  
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
      g_command = get_command(options[:type])
      relationship = self.send(g_command.to_sym).find{|r|r.id == options[:with]}
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
      (type == 'child') ? 'children' : "#{type}s"
    end
     
    def set_command(type)
      get_command(type)+"="
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
  
  class SearchPerson
    alias :name :full_name
    alias :ref :id
    def events
      (assertions && assertions.events) ? assertions.events : []
    end
    
    # Always will return nil. Method is here for v1 backwards compatibility
    def marriage
      nil
    end
  end
  
  class SearchResult
    alias :ref :id
    
    def father
      parents.find{|p|p.gender == 'Male'}
    end
    
    def mother
      parents.find{|p|p.gender == 'Female'}
    end
  end
  
  class PedigreePerson < Person
    attr_accessor :pedigree
    
    def initialize(pedigree = nil, person = nil)
      if person
        @id = person.id
        # @version = person.version if person.version
        @assertions = person.assertions if person.assertions
        @families = person.families if person.families
        @parents = person.parents if person.parents
      end
      if pedigree
        @pedigree = pedigree
      end
    end
    
    def father
      pedigree.get_person(father_id)
    end
    
    def mother
      pedigree.get_person(mother_id)
    end
        
  end
  
  class Pedigree
    attr_accessor :person_hash
    
    def initialize
      @person_hash = {}
      @persons = []
    end
    
    def injest(pedigree)
      @person_hash.merge!(pedigree.person_hash)
      graft_persons_to_self(pedigree.persons)
      @persons = @persons + pedigree.persons
    end
    
    def <<(person)
      p = PedigreePerson.new(self, person)
      @persons << p
      @person_hash[p.id] = p
    end
    
    def continue_nodes
      @persons.select do |person| 
        (!person.mother_id.nil? && person.mother.nil?) || (!person.father_id.nil? && person.father.nil?)
      end
    end
        
    def continue_node_ids
      continue_nodes.collect{|n|n.id}
    end
    
    def continue_ids
      cns = continue_nodes
      father_ids = cns.select{|n|!n.father_id.nil?}.collect{|n|n.father_id}
      mother_ids = cns.select{|n|!n.mother_id.nil?}.collect{|n|n.mother_id}
      father_ids + mother_ids
    end
        
    def get_person(id)
      @person_hash[id]
    end
    
    def person_ids
      @persons.collect{|p|p.id}
    end
    
    def init_jaxb_json_hash(_o)
      @id = String.from_json(_o['id']) unless _o['id'].nil?
      @requestedId = String.from_json(_o['requestedId']) unless _o['requestedId'].nil?
      if !_o['persons'].nil?
        @persons = Array.new
        _oa = _o['persons']
        _oa.each do | _item | 
          pedigree_person = Org::Familysearch::Ws::Familytree::V2::Schema::PedigreePerson.from_json(_item)
          pedigree_person.pedigree = self
          @persons.push pedigree_person
          @person_hash[pedigree_person.id] = pedigree_person
        end
      end
    end
    
    def root
      persons.first
    end
    
    private
    def graft_persons_to_self(persons_to_graft)
      persons_to_graft.each do |person|
        person.pedigree = self
      end
    end
    
  end
  
  class Note
    
    #Builds out the elements needed for the note.
    # ====Params
    # * <tt>options</tt> - Options for the note including the following:
    #   * <tt>:personId</tt> - the person ID if attaching to a person assertion.
    #   * <tt>:spouseIds</tt> - an Array of spouse IDs if creating a note attached to a spouse 
    #     relationship assertion.
    #   * <tt>:parentIds</tt> - an Array of parent IDs if creating a note attached to a parent 
    #     relationship assertion. If creating a note for a child-parent or parent-child 
    #     relationship, you will need only one parent ID in the array along with a :childId option.
    #   * <tt>:childId</tt> - a child ID.
    #   * <tt>:text</tt> - the text of the note (required).
    #   * <tt>:assertionId</tt> - the valueId of the assertion you are attaching this note to.
    def build(options)
      if spouseIds = options[:spouseIds]
        self.spouses = spouseIds.collect do |id|
          s = Org::Familysearch::Ws::Familytree::V2::Schema::EntityReference.new
          s.id = id
          s
        end
      end
      if parentIds = options[:parentIds]
        self.parents = parentIds.collect do |id|
          p = Org::Familysearch::Ws::Familytree::V2::Schema::EntityReference.new
          p.id = id
          p
        end
      end
      if personId = options[:personId]
        self.person = Org::Familysearch::Ws::Familytree::V2::Schema::EntityReference.new
        self.person.id = personId
      end
      if childId = options[:childId]
        self.child = Org::Familysearch::Ws::Familytree::V2::Schema::EntityReference.new
        self.child.id = childId
      end
      if assertionId = options[:assertionId]
        self.assertion = Org::Familysearch::Ws::Familytree::V2::Schema::EntityReference.new
        self.assertion.id = assertionId
      end
      if text = options[:text]
        self.text = text
      end
    end
  end
end