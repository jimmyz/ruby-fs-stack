# Put the lib directory on the load path 
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'ruby-fs-stack'
require 'pp'

communicator = FsCommunicator.new :domain => 'http://www.dev.usys.org', 
                                  :key => '',
                                  :user_agent => 'Ruby-Fs-Stack/v.1 (JimmyZimmerman) FsCommunicator/0.1 (Ruby)'

if communicator.identity_v1.authenticate :username => '', :password => ''
  me = ftcom.person :me
  puts "My name: " + me.full_name
  puts "My birthdate: " + me.birth.value.date.normalized

  vperson = ftcom.person 'KW3B-NNM', :names => 'none', :genders => 'none', :events => 'none'
  puts "Version Person"
  pp vperson
  
  person = ftcom.person 'KW3B-NNM', :parents => 'summary', :families => 'all', :children => 'all'
  
  puts person.gender
  puts "First parent ID: " + person.parents[0].parents[0].id
  puts "First child ID: " + person.families[0].children[0].id
  puts "First spouse's gender: " + person.families[0].parents[1].gender
  puts "First spouse's ID: " + person.families[0].parents[1].id
end