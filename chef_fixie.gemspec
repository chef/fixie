# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef_fixie/version"

Gem::Specification.new do |spec|
  spec.name          = "chef_fixie"
  spec.version       = ChefFixie::VERSION
  spec.authors       = ["Mark Anderson"]
  spec.email         = ["mark@chef.io"]
  spec.description   = %q{Low level manipulation tool for Chef Infra Server}
  spec.summary       = spec.description
  spec.licenses      = "Apache-2.0"
  spec.homepage      = "https://github.com/chef/fixie"

  spec.files         = %w{LICENSE README.md fixie.conf.example} + Dir.glob("{bin,doc,lib,spec}/**/*")
  spec.bindir        = "bin"
  spec.executables   = "chef_fixie"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "chef", ">= 17"
  spec.add_runtime_dependency "ffi-yajl", ">= 2.4.0"
  spec.add_runtime_dependency "pg", "~> 1.4", ">= 1.4.1"
  spec.add_runtime_dependency "pry", "~> 0.14"
  spec.add_runtime_dependency "sequel", ">= 5.58.0"
  spec.add_runtime_dependency "uuidtools", "~> 2.2", ">= 2.2.0"
  spec.add_runtime_dependency "bcrypt", "~> 3.1.18"
  spec.add_runtime_dependency "veil"
end
