require 'json'
require 'rspec'
require 'rspec/collection_matchers'
require 'webmock/rspec'
require 'factory_girl'
require 'rspec/its'

require_relative '../lib/docusign_rest'

RSpec.configure do |config|

  config.include FactoryGirl::Syntax::Methods
  FactoryGirl.find_definitions

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
