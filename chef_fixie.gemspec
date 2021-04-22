# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef_fixie/version"

Gem::Specification.new do |spec|
  spec.name          = "chef_fixie"
  spec.version       = ChefFixie::VERSION
  spec.authors       = ["Mark Anderson"]
  spec.email         = ["mark@chef.io"]
  spec.description   = %q{Low level manipulation tool for Chef Server 12 and later}
  spec.summary       = spec.description
  spec.licenses      = "Apache2"
  spec.homepage      = "https://github.com/chef/fixie"

  spec.files         = %w{LICENSE README.md fixie.conf.example} + Dir.glob("{bin,doc,lib,spec}/**/*")
  spec.bindir        = "bin"
  spec.executables   = "chef_fixie"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "chef", "~> 15.2"
  spec.add_runtime_dependency "ffi-yajl", ">= 1.2.0"
  spec.add_runtime_dependency "pg", "~> 0.17", ">= 0.17.1"
  spec.add_runtime_dependency "pry", "~> 0.10.1"
  spec.add_runtime_dependency "sequel", "~> 4.11"
  spec.add_runtime_dependency "uuidtools", "~> 2.1", ">= 2.1.3"
  spec.add_runtime_dependency "veil"

  spec.add_development_dependency "rake", "~> 0"
  spec.add_development_dependency "rspec", "~> 0"
end
