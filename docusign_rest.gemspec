# -*- encoding: utf-8 -*-
require File.expand_path('../lib/docusign_rest/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Jon Kinney']
  gem.email         = ['jonkinney@gmail.com']
  gem.description   = %q{Hooks a Rails app up to the DocuSign service through the DocuSign REST API}
  gem.summary       = %q{Use this gem to embed signing of documents in a Rails app through the DocuSign REST API}
  gem.homepage      = "https://github.com/jondkinney/docusign_rest"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'docusign_rest'
  gem.require_paths = ['lib']
  gem.version       = DocusignRest::VERSION

  gem.required_ruby_version = '>= 2.2.2'

  gem.add_dependency('activesupport')
  gem.add_dependency('multipart-post', '>= 1.2')
  gem.add_dependency('json')
  gem.add_dependency('andand')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('minitest')
  gem.add_development_dependency('guard-minitest')
  gem.add_development_dependency('rb-fsevent')
  gem.add_development_dependency('turn')
  gem.add_development_dependency('pry')
  gem.add_development_dependency('vcr')
  gem.add_development_dependency('factory_girl')
  gem.add_development_dependency('webmock')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('rspec-nc')
  gem.add_development_dependency('rspec-its')
  gem.add_development_dependency('rspec-collection_matchers')
  gem.add_development_dependency('fakeweb')
end
