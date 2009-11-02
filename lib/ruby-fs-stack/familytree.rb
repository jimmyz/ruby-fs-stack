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
  # you can make calls on the fs_familytree_v1 module
  def familytree_v2
    @familytree_v2_com ||= Communicator.new self # self at this point refers to the FsCommunicator instance
  end
  
  class Communicator
    Base = '/familytree/v2/'
    
    # ==params
    # fs_communicator: FsCommunicator instance
    def initialize(fs_communicator)
      @fs_communicator = fs_communicator
    end
    
    # ===params
    # <tt>id</tt> should be a string of the persons identifier. For the 'me' person, use :me or 'me'
    # <tt>options</tt> NOT IMPLEMENTED YET
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
          p.predelimiters = " "
          p.value = piece
          p
        end
      else
        self.fullText = name
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
  end

  class Person
    
    def full_names
      if assertions && assertions.names
        return assertions.names.collect do |name|
          name.value.forms[0].fullText
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
      if assertions && assertions.events
        assertions.events.select{|e| e.value.type == 'Birth'}
      else
        []
      end
    end
    
    # It should return the selected birth assertion unless it is
    # not set in which case it will return the first
    def birth
      birth = births.find{|b|!b.selected.nil?}
      birth ||= births[0]
      birth
    end
  
    protected
    def add_assertions!
      if assertions.nil?
        self.assertions = PersonAssertions.new
      end
    end
  
  end
end