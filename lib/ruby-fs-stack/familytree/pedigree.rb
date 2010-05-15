module Org::Familysearch::Ws::Familytree::V2::Schema
  class PedigreePerson < Person
    attr_accessor :pedigree
    
    def initialize(pedigree = nil, person = nil)
      if person
        @id = person.id
        # @version = person.version if person.version
        @assertions = person.assertions if person.assertions
        @families = person.families if person.families
        @parents = person.parents if person.parents
        @properties = person.properties if person.properties
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
end