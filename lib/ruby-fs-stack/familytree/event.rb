module Org::Familysearch::Ws::Familytree::V2::Schema
  
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
end