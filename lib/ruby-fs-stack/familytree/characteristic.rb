module Org::Familysearch::Ws::Familytree::V2::Schema
    
  class CharacteristicAssertion
    # ====Params
    # * <tt>options</tt> - same as RelationshipAssertions#add_characteristic
    def add_value(options)
      self.value = CharacteristicValue.new
      self.value.type = options[:type]
      self.value.lineage = options[:lineage] if options[:lineage]
    end
  end
end