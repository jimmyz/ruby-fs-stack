
module RubyFsStack
  class FamilySearchError < StandardError
    attr_reader :communicator
    def initialize(msg = nil, communicator = nil)
      @communicator = communicator if communicator
      super(msg)
    end
  end
  
  # 310 	The user needs to go to the family tree and perform 
  # some action, such as read a new version of the conditions of use.
  class UserActionRequired < FamilySearchError
  end
  
  # 400 	Bad Request. Generic client error or multiple client errors.
  class BadRequest < FamilySearchError
  end
  
  # 401 	Unauthorized. The user has invalid credentials or the session 
  # ID is missing, invalid, or has expired. This error also appears if 
  # the query string contains multiple question marks or the the session 
  # parameter contains letters in an incorrect case.
  class Unauthorized < FamilySearchError
  end
  
  # 403 	Forbidden. The user does not have sufficient rights to perform 
  # the operation.
  class Forbidden < FamilySearchError
  end
  
  # 404   Not Found. This request contained an invalid ID or a bad URI.
  class NotFound < FamilySearchError
  end
  
  # 409 	Conflict. The action could not be performed because it would 
  # create a conflict.
  class Conflict < FamilySearchError
  end
  
  # 410   Gone. The requested resource has been deleted or recanted OR the 
  # requested version of the API has been retired.
  class Gone < FamilySearchError
  end
  
  # 415 	Unsupported media type, invalid content-type in header, or invalid 
  # character encoding.
  class InvalidContentType < FamilySearchError
  end
  
  # 430 	Bad version. Incorrect version of the object.
  class BadVersion < FamilySearchError
  end
  
  # 431   Invalid developer key.
  class InvalidDeveloperKey < FamilySearchError
  end
  
  # 500   Server Error. A generic server error or multiple server errors 
  # occurred. If you get this error, please report it at https://issues.devnet.familysearch.org. 
  class ServerError < FamilySearchError
  end
  
  # 501 	Not Implemented. The requested service or combination of parameters 
  # has not been implemented.
  class NotImplemented < FamilySearchError
  end
  
  # 503 	Service Unavailable. FamilySearch or the service that you are using is not currently 
  # available. Or you are being throttled.
  class ServiceUnavailable < FamilySearchError
  end  
  
end
