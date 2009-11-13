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
    # <tt>id</tt> should be a string of the persons identifier. For the 'me' person, use :me or 'me'
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
    def person(id, options = {})
      id = id.to_s
      if id == 'me'
        url = Base + 'person'
      else
        url = Base + 'person/' + id
      end
      url += "?"+FsUtils.querystring_from_hash(options) unless options.empty?
      response = @fs_communicator.get(url)
      familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      person = familytree.persons.find{|p| p.requestedId == id }
      person ||= familytree.persons.first if id == 'me'
      person
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
      self.pieces.collect{|piece| "#{piece.predelimiters}#{piece.value}#{piece.postdelimiters}"}.join('')
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
  end
  
  class OrdinanceValue
    
    def add_date(value)
      self.date = GenDate.new
      self.date.original = value
    end
    
  end
  
  class OrdinanceAssertion
    
    def add_value(options)
      raise ArgumentError, "missing option[:type]" if options[:type].nil?
      self.value = OrdinanceValue.new
      self.value.type = options[:type]
      self.value.add_date(options[:date]) if options[:date]
      self.value.temple = options[:temple] if options[:temple]
    end
  end

  class PersonAssertions
    def add_gender(value)
      self.genders ||= []
      g = GenderAssertion.new
      g.add_value('Male')
      self.genders << g
    end
    
    def add_name(value)
      self.names ||= []
      n = NameAssertion.new
      n.add_value(value)
      self.names << n
    end
        
    def add_event(options)
      self.events ||= []
      e = EventAssertion.new
      e.add_value(options)
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
    
    # Add a baptism ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date and :temple option
    #
    # ====Example
    #
    #   person.add_baptism :date => '14 Aug 2009', :temple => 'SGEOR'
    def add_baptism(options)
      add_assertions!
      options[:type] = 'Baptism'
      assertions.add_ordinance(options)
    end
    
    # Add a confirmation ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date and :temple option
    #
    # ====Example
    #
    #   person.add_confirmation :date => '14 Aug 2009', :temple => 'SGEOR'
    def add_confirmation(options)
      add_assertions!
      options[:type] = 'Confirmation'
      assertions.add_ordinance(options)
    end
    
    # Add a initiatory ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date and :temple option
    #
    # ====Example
    #
    #   person.add_initiatory :date => '14 Aug 2009', :temple => 'SGEOR'
    def add_initiatory(options)
      add_assertions!
      options[:type] = 'Initiatory'
      assertions.add_ordinance(options)
    end
    
    # Add a endowment ordinance
    # 
    # ====Params
    # * <tt>options</tt> - accepts a :date and :temple option
    #
    # ====Example
    #
    #   person.add_endowment :date => '14 Aug 2009', :temple => 'SGEOR'
    def add_endowment(options)
      add_assertions!
      options[:type] = 'Endowment'
      assertions.add_ordinance(options)
    end
  
    private
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
    
    def select_ordinances(type)
      if assertions && assertions.ordinances
        assertions.ordinances.select{|e| e.value.type == type}
      else
        []
      end
    end
  
  end
end