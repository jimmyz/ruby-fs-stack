require 'ruby-fs-stack/identity'
require 'ruby-fs-stack/familytree'

module RubyFsStack
  def self.version
    @@version ||= File.read(File.join(File.dirname(__FILE__),'..','VERSION')).strip
  end
end