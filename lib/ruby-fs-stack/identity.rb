require 'rubygems'
require 'ruby-fs-stack/identity/communicator'
# Including more than one enunciate library raises a warning of
# already initialized constant.
require 'ruby-fs-stack/warning_suppressor'
with_warnings_suppressed do
  require 'ruby-fs-stack/enunciate/identity'
end

