module Org::Familysearch::Ws::Familytree::V2::Schema
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