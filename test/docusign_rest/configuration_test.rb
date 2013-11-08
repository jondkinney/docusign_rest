require_relative '../helper'

describe 'configuration' do
  after do
    DocusignRest.reset
  end

  describe '.configure' do
    DocusignRest::Configuration::VALID_CONFIG_KEYS.each do |key|
      it "should set the #{key}" do
        DocusignRest.configure do |config|
          config.send("#{key}=", key)
          DocusignRest.send(key).must_equal key
        end
      end

      describe '.key' do
        it "should return default value for #{key}" do
          DocusignRest.send(key).must_equal DocusignRest::Configuration.const_get("DEFAULT_#{key.upcase}")
        end
      end
    end
  end
end
