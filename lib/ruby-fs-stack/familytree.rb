require 'rubygems'
require 'ruby-fs-stack/familytree/communicator'

# Including more than one enunciate library raises a warning of
# already initialized constant.
require 'ruby-fs-stack/warning_suppressor'
with_warnings_suppressed do
  require 'ruby-fs-stack/enunciate/familytree'
end

require 'ruby-fs-stack/familytree/gender'
require 'ruby-fs-stack/familytree/name'
require 'ruby-fs-stack/familytree/event'
require 'ruby-fs-stack/familytree/ordinance'
require 'ruby-fs-stack/familytree/characteristic'
require 'ruby-fs-stack/familytree/exist'
require 'ruby-fs-stack/familytree/relationship'
require 'ruby-fs-stack/familytree/person'
require 'ruby-fs-stack/familytree/search'
require 'ruby-fs-stack/familytree/match'
require 'ruby-fs-stack/familytree/pedigree'
require 'ruby-fs-stack/familytree/note'

