# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'refile/skeptick/version'

Gem::Specification.new do |spec|
  spec.name          = "refile-skeptick"
  spec.version       = Refile::Skeptick::VERSION
  spec.authors       = ["Maxim Chernayk"]
  spec.email         = ["madfancier@gmail.com"]
  spec.summary       = "Image processing via Skeptick for Refile"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "refile", "~> 0.5"
  spec.add_dependency "skeptick", "~> 0.2"
end
