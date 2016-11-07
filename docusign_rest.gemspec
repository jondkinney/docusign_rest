# -*- encoding: utf-8 -*-
require File.expand_path('../lib/docusign_rest/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Jon Kinney', 'Tom Copeland']
  gem.email         = ['jonkinney@gmail.com', 'tom@thomasleecopeland.com']
  gem.description   = %q{Hooks a Rails app up to the DocuSign service through the DocuSign REST API}
  gem.summary       = %q{Use this gem to embed signing of documents in a Rails app through the DocuSign REST API}
  gem.homepage      = "https://github.com/jondkinney/docusign_rest"

  gem.files         = `git ls-files -z`.split("\x0").reject {|p| p.match(%r{^(test/|test.*pdf|cacert.pem|.gitignore)}) }
  gem.name          = 'docusign_rest'
  gem.require_paths = ['lib']
  gem.version       = DocusignRest::VERSION
  gem.licenses      = ['MIT']

  gem.required_ruby_version = '>= 2.1.0'

  gem.add_dependency('multipart-post', '>= 1.2')
  gem.add_dependency('json')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('byebug')
  gem.add_development_dependency('minitest', '~> 4.0')
  gem.add_development_dependency('rb-fsevent', '~> 0.9')
  gem.add_development_dependency('turn')
  gem.add_development_dependency('pry')
  gem.add_development_dependency('vcr')
  gem.add_development_dependency('webmock')
  gem.add_development_dependency('safe_yaml')
end
