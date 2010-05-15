module Org::Familysearch::Ws::Familytree::V2::Schema
    
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
end