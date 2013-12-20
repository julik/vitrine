# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "vitrine"
  s.version = "0.0.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julik Tarkhanov"]
  s.date = "2013-12-20"
  s.description = " Serves ERB templates with live CoffeeScript and SASS "
  s.email = "me@julik.nl"
  s.executables = ["vitrine"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Guardfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "bin/vitrine",
    "lib/atomic_write.rb",
    "lib/server.rb",
    "lib/sourcemaps.rb",
    "lib/version.rb",
    "lib/vitrine.rb",
    "test/helper.rb",
    "test/test_vitrine.rb",
    "test/test_vitrine_in_rack_stack.rb",
    "vitrine.gemspec"
  ]
  s.homepage = "http://github.com/julik/vitrine"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Quickie micro-app preview server"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_runtime_dependency(%q<coffee-script>, ["~> 2.2"])
      s.add_runtime_dependency(%q<sass>, ["~> 3"])
      s.add_runtime_dependency(%q<guard>, ["~> 2.2"])
      s.add_runtime_dependency(%q<guard-livereload>, [">= 0"])
      s.add_runtime_dependency(%q<rack-contrib>, [">= 0"])
      s.add_runtime_dependency(%q<rack-livereload>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.7"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<guard-test>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
    else
      s.add_dependency(%q<sinatra>, ["~> 1.4"])
      s.add_dependency(%q<coffee-script>, ["~> 2.2"])
      s.add_dependency(%q<sass>, ["~> 3"])
      s.add_dependency(%q<guard>, ["~> 2.2"])
      s.add_dependency(%q<guard-livereload>, [">= 0"])
      s.add_dependency(%q<rack-contrib>, [">= 0"])
      s.add_dependency(%q<rack-livereload>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<guard-test>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
    end
  else
    s.add_dependency(%q<sinatra>, ["~> 1.4"])
    s.add_dependency(%q<coffee-script>, ["~> 2.2"])
    s.add_dependency(%q<sass>, ["~> 3"])
    s.add_dependency(%q<guard>, ["~> 2.2"])
    s.add_dependency(%q<guard-livereload>, [">= 0"])
    s.add_dependency(%q<rack-contrib>, [">= 0"])
    s.add_dependency(%q<rack-livereload>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<guard-test>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
  end
end

