require 'ruby-fs-stack/fs_communicator'
require 'ruby-fs-stack/fs_utils'

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
    # 
    # ===Blocks
    # A block is available for this method, so that you can register a callback of sorts
    # for when a read has been completed. 
    # 
    # For example, if I were to send 500 person IDs to
    # this method and the current person.max.ids was 10, 50 person reads would be performed
    # to gather all of the records. This could take some time, so you may want to present a
    # progress of sorts to the end-user. Using a block enables this to be done.
    # 
    #   ids = [] #array of 500 ids
    #   running_total = 0
    #   persons = communicator.familytree_v2.person ids, :parents => 'summary' do |people|
    #     running_total += ps.size
    #     puts running_total
    #   end
    # 
    #   # If you are only requesting a single individual, the block will be passed a single person record
    #   person = communicator.familytree_v2.person :me do |p|
    #     puts p.id
    #   end
    # 
    # ===500 Errors
    # Occasionally, the FamilySearch API returns 500 errors when reading a person record.
    # This is problematic when you are requesting 100+ person records from the person read 
    # because it may happen towards the end of your entire batch and it causes the entire
    # read to fail. Rather than fail, it does the following.
    # 
    # If you are requesting multiple IDs and a 500 is thrown when requesting 10 records, it is
    # possible that only 1 of the 10 person records actually caused the problem, so this will
    # re-request the records individually.
    # 
    # If a single record throws a 500, then the response will be an empty person record with only
    # an ID.
    # 
    def person(id_or_ids, options = {}, &block)
      if id_or_ids.kind_of? Array
        return multi_person_read(id_or_ids,options,&block)
      else
        return single_person_read(id_or_ids.to_s,options,&block)
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
      
      # Get the most current related ID for the URI
      rels = person.relationships.get_relationships_of_type(r_options[:type])
      rel = rels.find{|r|r.id == r_options[:with] || r.requestedId == r_options[:with]}
      related_id = rel.id
      url = "#{Base}person/#{base_id}/#{relationship_type}/#{related_id}"
      
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
      familytree = parse_response(response)
      if multiple_ids
        return familytree.pedigrees
      else
        pedigree = familytree.pedigrees.find{|p| p.requestedId == id }
        pedigree ||= familytree.pedigrees.first if id == 'me'
        return pedigree
      end
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
    def contributor(id_or_ids)
      if id_or_ids.kind_of? Array
        multiple_ids = true
        url = Base + 'contributor/' + id_or_ids.join(',')
        props = properties()
        if id_or_ids.size > props['contributor.max.ids'] 
          contributors = []
          id_or_ids.each_slice(props['contributor.max.ids']) do |ids_slice|
            contributors = contributors + contributor(ids_slice)
          end
          return contributors
        end
      else
        multiple_ids = false
        id = id_or_ids.to_s
        if id == 'me'
          url = Base + 'contributor'
        else
          url = Base + 'contributor/' + id
        end
      end
      response = @fs_communicator.get(url)
      familytree = parse_response(response)
      if multiple_ids
        return familytree.contributors
      else
        return familytree.contributors.first
      end
    end
    
    def properties
      if @properties_hash
        return @properties_hash
      else
        url = Base + 'properties'
        response = @fs_communicator.get(url)
        familytree = parse_response(response)
        @properties_hash = {}
        familytree.properties.each do |prop|
          @properties_hash[prop.name] = prop.value.to_i
        end
        return @properties_hash
      end
    end
    
    private
    
    def multi_person_read(ids,options,&block)
      url = Base + 'person/' + ids.join(',')
      props = properties()
      if ids.size > props['person.max.ids'] 
        persons = []
        ids.each_slice(props['person.max.ids']) do |ids_slice|
          persons = persons + person(ids_slice,options,&block)
        end
        return persons
      end
      url += add_querystring(options)
      begin
        response = @fs_communicator.get(url)
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      rescue RubyFsStack::ServerError => e 
        persons = []
        ids.each do |id|
          persons << person(id,options)
        end
        return persons
      end
      yield(familytree.persons) if block
      return familytree.persons
    end
    
    def single_person_read(id,options,&block)
      if id == 'me'
        url = Base + 'person'
      else
        url = Base + 'person/' + id
      end
      url += add_querystring(options)
      begin
        response = @fs_communicator.get(url)
        familytree = Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
      rescue RubyFsStack::ServerError => e 
        person = Org::Familysearch::Ws::Familytree::V2::Schema::Person.new
        person.id = id
        person.requestedId = id
        return person
      end
      person = familytree.persons.find{|p| p.requestedId == id }
      person ||= familytree.persons.first if id == 'me'
      yield(person) if block
      return person
    end
    
    def parse_response(response)
      Org::Familysearch::Ws::Familytree::V2::Schema::FamilyTree.from_json JSON.parse(response.body)
    end
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