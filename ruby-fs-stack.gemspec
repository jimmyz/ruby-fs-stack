# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-fs-stack}
  s.version = "0.4.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jimmy Zimmerman"]
  s.date = %q{2010-04-07}
  s.description = %q{A library that enables you to read and update information with the new.familysearch.org API.}
  s.email = %q{jimmy.zimmerman@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "examples/familytree_example.rb",
     "examples/login_example.rb",
     "lib/ruby-fs-stack.rb",
     "lib/ruby-fs-stack/assets/entrust-ca.crt",
     "lib/ruby-fs-stack/enunciate/LICENSE",
     "lib/ruby-fs-stack/enunciate/README",
     "lib/ruby-fs-stack/enunciate/familytree.rb",
     "lib/ruby-fs-stack/enunciate/identity.rb",
     "lib/ruby-fs-stack/errors.rb",
     "lib/ruby-fs-stack/familytree.rb",
     "lib/ruby-fs-stack/fs_communicator.rb",
     "lib/ruby-fs-stack/fs_utils.rb",
     "lib/ruby-fs-stack/identity.rb",
     "lib/ruby-fs-stack/warning_suppressor.rb",
     "ruby-fs-stack.gemspec",
     "spec/communicator_spec.rb",
     "spec/familytree_v2/familytree_communicator_spec.rb",
     "spec/familytree_v2/json/combine_request.js",
     "spec/familytree_v2/json/combine_response.js",
     "spec/familytree_v2/json/fakeweb_contributor.txt",
     "spec/familytree_v2/json/fakeweb_pedigree.txt",
     "spec/familytree_v2/json/fakeweb_pedigree2.txt",
     "spec/familytree_v2/json/fakeweb_properties.txt",
     "spec/familytree_v2/json/match_KW3B-NNM.js",
     "spec/familytree_v2/json/note_create_response.js",
     "spec/familytree_v2/json/person/KJ86-3VD_all.js",
     "spec/familytree_v2/json/person/KJ86-3VD_parents_families.js",
     "spec/familytree_v2/json/person/KJ86-3VD_version.js",
     "spec/familytree_v2/json/person/fakeweb_10_batch.txt",
     "spec/familytree_v2/json/person/fakeweb_6_batch.txt",
     "spec/familytree_v2/json/person/multiple_version_read.js",
     "spec/familytree_v2/json/person/post_response.js",
     "spec/familytree_v2/json/person/relationship_not_found.js",
     "spec/familytree_v2/json/person/relationship_read.js",
     "spec/familytree_v2/json/person/relationship_update.js",
     "spec/familytree_v2/json/person/spouse_read.js",
     "spec/familytree_v2/json/search.js",
     "spec/familytree_v2/match_results_spec.rb",
     "spec/familytree_v2/note_spec.rb",
     "spec/familytree_v2/pedigree_spec.rb",
     "spec/familytree_v2/person_spec.rb",
     "spec/familytree_v2/search_results_spec.rb",
     "spec/fixtures/fakeweb_response.txt",
     "spec/fs_utils_spec.rb",
     "spec/identity_v1/identity_spec.rb",
     "spec/identity_v1/json/login.js",
     "spec/ruby-fs-stack_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/jimmyz/ruby-fs-stack}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.requirements = ["This gem requires a json gem (json, json_pure, or json-jruby)."]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Ruby wrapper for all FamilySearch APIs.}
  s.test_files = [
    "spec/communicator_spec.rb",
     "spec/familytree_v2/familytree_communicator_spec.rb",
     "spec/familytree_v2/match_results_spec.rb",
     "spec/familytree_v2/note_spec.rb",
     "spec/familytree_v2/pedigree_spec.rb",
     "spec/familytree_v2/person_spec.rb",
     "spec/familytree_v2/search_results_spec.rb",
     "spec/fs_utils_spec.rb",
     "spec/identity_v1/identity_spec.rb",
     "spec/ruby-fs-stack_spec.rb",
     "spec/spec_helper.rb",
     "examples/familytree_example.rb",
     "examples/login_example.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<fakeweb>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<fakeweb>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<fakeweb>, [">= 0"])
  end
end
