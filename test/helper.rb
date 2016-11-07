require_relative '../lib/docusign_rest'
require 'minitest/spec'
require 'minitest/autorun'
require 'turn'
require 'json'
require 'vcr'
require_relative 'docusign_login_config'
require 'pry'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/vcr"
  c.hook_into :webmock
  c.default_cassette_options = { record: :all }

  c.filter_sensitive_data('<Password>') do
    DocusignRest.password
  end

  c.filter_sensitive_data('<IntegratorKey>') do
    DocusignRest.integrator_key
  end

  c.filter_sensitive_data('<Username>') do
    DocusignRest.username
  end

  c.filter_sensitive_data('<AccountID>') do
    DocusignRest.account_id
  end
end
