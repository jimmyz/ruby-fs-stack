# Put the lib directory on the load path 
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'ruby-fs-stack'

communicator = FsCommunicator.new :domain => 'http://www.dev.usys.org', 
                                  :key => '',
                                  :user_agent => 'Ruby-Fs-Stack/v.1 (JimmyZimmerman) FsCommunicator/0.1 (Ruby)'

if communicator.identity_v1.authenticate :username => '', :password => ''
  person = communicator.familytree_v2.person :me
  puts person.full_name
  puts person.birth.value.date.normalized
end