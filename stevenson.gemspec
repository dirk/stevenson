# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stevenson/version'

Gem::Specification.new do |s|
  s.name = %q{stevenson}
  s.version = Stevenson::VERSION
  s.authors = ["Dirk Gadsden"]
  s.email = ["dirk@esherido.com"]
  s.description = ""
  s.summary = ""
  s.homepage = "https://github.com/dirk/stevenson"
  
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "README.textile",
    "Rakefile",
    "VERSION",
    "lib/stevenson.rb",
    "lib/stevenson/application.rb",
    "lib/stevenson/delegator.rb",
    "lib/stevenson/nest.rb",
    "lib/stevenson/nests/collection.rb",
    "lib/stevenson/page.rb",
    "lib/stevenson/server.rb",
    "lib/stevenson/templates.rb",
    "stevenson.gemspec",
    # "test/about.rb",
    # "test/app.rb",
    # "test/config.ru",
    # "test/index.erb",
    # "test/index.rb",
    # "test/layouts/default.erb",
    # "test/people.erb",
    # "test/people.rb",
    # "test/people/jane.rb",
    # "test/people/jane_smith.erb",
    # "test/people/john.rb",
    # "test/people/john_smith.erb",
    # "test/public/images/barcamp.png",
    # "test/sinatra_test_app.rb",
    # "test/sinatra_test_config.ru"
  ]
  s.require_paths = ["lib"]
  
  s.add_dependency(%q<sinatra>, [">= 1.1.0"])
  s.add_dependency(%q<haml>, [">= 3.0.24"])
  s.add_dependency(%q<rack>, [">= 0"])
end

