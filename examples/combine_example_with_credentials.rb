$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'ruby-fs-stack'
require 'pp'

communicator = FsCommunicator.new :domain => 'http://www.dev.usys.org', 
                                  :key => 'WCQY-7J1Q-GKVV-7DNM-SQ5M-9Q5H-JX3H-CMJK',
                                  :user_agent => 'Ruby-Fs-Stack/v.1 (JimmyZimmerman) FsCommunicator/0.1 (Ruby)'

if communicator.identity_v1.authenticate :username => 'api-user-1241', :password => '1782'
  FamilyTreeV2 = Org::Familysearch::Ws::Familytree::V2::Schema
  # p = FamilyTreeV2::Person.new
  # p.add_name "Jonathan /Duplicate/"
  # p.add_gender "Male"
  # p.add_birth :date => "1775"
  # p1 = communicator.familytree_v2.save_person p
  # pp p1
  # p2 = communicator.familytree_v2.save_person p
  # pp p2
  # p3 = communicator.familytree_v2.save_person p
  # pp p3
  person_ids = ['KW3B-VZ6', 'KW3B-VZX', 'KW3B-VZF']
  persons = communicator.familytree_v2.person person_ids # [p1.id,p2.id,p3.id]
  pp persons
  new_person = communicator.familytree_v2.combine person_ids
end