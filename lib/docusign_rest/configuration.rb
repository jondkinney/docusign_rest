module DocusignRest
  module Configuration
    VALID_CONNECTION_KEYS  = [:endpoint, :api_version, :user_agent, :method].freeze
    VALID_OPTIONS_KEYS     = [:access_token, :username, :password, :integrator_key, :account_id, :format, :ca_file].freeze
    VALID_CONFIG_KEYS      = VALID_CONNECTION_KEYS + VALID_OPTIONS_KEYS

    DEFAULT_ENDPOINT       = 'https://demo.docusign.net/restapi'
    DEFAULT_API_VERSION    = 'v1'
    DEFAULT_USER_AGENT     = "DocusignRest API Ruby Gem #{DocusignRest::VERSION}".freeze
    DEFAULT_METHOD         = :get

    DEFAULT_USERNAME       = nil
    DEFAULT_PASSWORD       = nil
    DEFAULT_INTEGRATOR_KEY = nil
    DEFAULT_ACCOUNT_ID     = nil
    DEFAULT_CA_FILE        = nil
    DEFAULT_FORMAT         = :json

    # Build accessor methods for every config options so we can do this, for example:
    #   DocusignRest.format = :xml
    attr_accessor *VALID_CONFIG_KEYS

    # Make sure we have the default values set when we get 'extended'
    def self.extended(base)
      base.reset
    end

    def reset
      self.endpoint       = DEFAULT_ENDPOINT
      self.api_version    = DEFAULT_API_VERSION
      self.user_agent     = DEFAULT_USER_AGENT
      self.method         = DEFAULT_METHOD

      self.access_token    = nil

      self.username       = DEFAULT_USERNAME
      self.password       = DEFAULT_PASSWORD
      self.integrator_key = DEFAULT_INTEGRATOR_KEY
      self.account_id     = DEFAULT_ACCOUNT_ID
      self.format         = DEFAULT_FORMAT
      self.ca_file        = DEFAULT_CA_FILE
    end

    # Allow configuration via a block
    def configure
      yield self
    end

    def options
      Hash[ * VALID_CONFIG_KEYS.map { |key| [key, send(key)] }.flatten ]
    end
  end
end
