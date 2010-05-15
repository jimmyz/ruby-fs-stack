module Org::Familysearch::Ws::Familytree::V2::Schema
  
  class ExistsAssertion
    def add_value
      self.value = ExistsValue.new
    end
  end
end