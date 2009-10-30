require 'rubygems'
require 'communicator'
# Including more than one enunciate library raises a warning of
# already initialized constant.
require 'ruby-fs-stack/warning_suppressor'
with_warnings_suppressed do
  require 'ruby-fs-stack/enunciate/identity'
end

module IdentityV1
  
  # This method gets mixed into the FsCommunicator so that
  # you can make calls on the fs_familytree_v1 module
  def identity_v1
    @identity_v1_com ||= Communicator.new self # self at this point refers to the FsCommunicator instance
  end
  
  class Communicator
    Base = '/identity/v1/'
    
    # ====params
    # fs_communicator: FsCommunicator instance
    def initialize(fs_communicator)
      @communicator = fs_communicator
    end
    
    # ==== Params
    # <tt>credentials</tt> - :username, :password
    def authenticate(credentials = {})
      url = Base + 'login'
      response = @communicator.get(url, credentials)
      login_result = Org::Familysearch::Ws::Identity::V1::Schema::Identity.from_json JSON.parse(response.body)
      if login_result.statusCode == 200
        @communicator.session = login_result.session.id
        return true
      end
    end
  end
  
end

# Mix in the module so that the identity_v1 can be called
class FsCommunicator
  include IdentityV1
end