module Org::Familysearch::Ws::Familytree::V2::Schema
  
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
end