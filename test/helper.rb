require 'docusign_rest'
require 'minitest/spec'
require 'minitest/autorun'
require 'turn'
require 'json'
require 'vcr'
require 'docusign_login_config'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/vcr"
  c.hook_into :fakeweb

  c.filter_sensitive_data('%ACCOUNT_ID%') { DocusignRest.account_id }
  c.filter_sensitive_data('%USERNAME%') { DocusignRest.username }
  c.filter_sensitive_data('%PASSWORD%') { DocusignRest.password }
  c.filter_sensitive_data('%INTEGRATOR_KEY%') { DocusignRest.integrator_key }
end
