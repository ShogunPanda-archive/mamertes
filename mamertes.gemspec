# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "./lib/mamertes/version"

Gem::Specification.new do |gem|
  gem.name = "mamertes"
  gem.version = Mamertes::Version::STRING
  gem.authors = ["Shogun"]
  gem.email = ["shogun@cowtech.it"]
  gem.homepage = "http://sw.cow.tc/mamertes"
  gem.summary = %q{Yet another command line manager.}
  gem.description = %q{Yet another command line manager.}

  gem.rubyforge_project = "mamertes"
  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 1.9.3"

  gem.add_dependency("bovem", "~> 2.4.0")
end



