require_relative '../lib/docusign_rest'
require 'minitest/spec'
require 'minitest/autorun'
require 'turn'
require 'json'
require 'vcr'
require_relative 'docusign_login_config'
require 'pry'
require 'safe_yaml'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures/vcr"
  c.hook_into :fakeweb
  c.default_cassette_options = { record: :all }

  docusign_config = YAML.load(File.open("docusign_config.yml"))

  c.filter_sensitive_data('<Password>') do
    docusign_config["password"]
  end

  c.filter_sensitive_data('<IntegratorKey>') do
    docusign_config["integrator_key"]
  end

  c.filter_sensitive_data('<Username>') do
    docusign_config["username"]
  end

  c.filter_sensitive_data('<AccountID>') do
    docusign_config["account_id"]
  end
end
