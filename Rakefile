require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ruby-fs-stack"
    gem.summary = %Q{Ruby wrapper for all FamilySearch APIs.}
    gem.description = %Q{A library that enables you to read and update information with the new.familysearch.org API.}
    gem.email = "jimmy.zimmerman@gmail.com"
    gem.homepage = "http://github.com/jimmyz/ruby-fs-stack"
    gem.authors = ["Jimmy Zimmerman"]
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "fakeweb"
    gem.requirements << "This gem requires a json gem (json, json_pure, or json-jruby)."
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby-fs-stack #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
