module Org::Familysearch::Ws::Familytree::V2::Schema
    
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
    
    def surname
      if self.pieces.nil?
        (self.fullText.nil?) ? nil : self.fullText.split(' ').last
      else
        piece = self.pieces.find{|piece|piece.type == 'Family'}
        (piece.nil?) ? nil : piece.value
      end
    end
    
    def buildFullText
      if self.pieces.nil?
        return ''
      else
        self.pieces.collect{|piece| "#{piece.predelimiters}#{piece.value}#{piece.postdelimiters}"}.join('')
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
    
    def select(value_id)
      self.action = 'Select'
      self.value = AssertionValue.new
      self.value.id = value_id
    end
  end
end