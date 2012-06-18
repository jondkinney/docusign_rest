# -*- encoding: utf-8 -*-
require File.expand_path('../lib/docusign_rest/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jon Kinney"]
  gem.email         = ["jonkinney@gmail.com"]
  gem.description   = %q{Hooks a Rails app up to the DocuSign service through the DocuSign REST API}
  gem.summary       = %q{Use this gem to embed signing of documents in a Rails app through the DocuSign REST API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "docusign_rest"
  gem.require_paths = ["lib"]
  gem.version       = DocusignRest::VERSION

  gem.add_dependency('multipart-post', '>= 1.1.5')
  gem.add_dependency('json')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('minitest')
  #gem.add_development_dependency('m')
  gem.add_development_dependency('turn')
  # need this older version of pry below to accomodate the fact that the 'm' gem
  # relies explicitally on a version of the method_source gem and the latest
  # pry uses a much higher version.
  #gem.add_development_dependency('pry', '0.9.7.4')
  gem.add_development_dependency('pry')
  gem.add_development_dependency('vcr')
  gem.add_development_dependency('fakeweb')
end
