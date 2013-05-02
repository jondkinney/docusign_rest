require 'docusign_rest'
require 'minitest/spec'
require 'minitest/autorun'
require 'turn'
require 'json'
require 'vcr'
require 'docusign_login_config'
require 'pry'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/vcr"
  c.hook_into :fakeweb
end
