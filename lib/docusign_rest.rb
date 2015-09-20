require_relative 'docusign_rest/version'
require_relative 'docusign_rest/configuration'
require_relative 'docusign_rest/client'
require_relative 'docusign_rest/utility'
require_relative 'models/envelope'
require_relative 'models/recipient'
require_relative 'models/tab'
require_relative 'models/tabs_updater'
require_relative 'models/tabs/checkbox_tab'
require_relative 'models/tabs/text_tab'
require 'active_support/core_ext'
require 'multipart_post' #require the multipart-post gem itself
require 'net/http/post/multipart' #require the multipart-post net/http/post/multipart monkey patch
require_relative 'multipart_post/parts' #require my monkey patched parts.rb which adjusts the build_part method
require 'net/http'
require 'json'
require 'andand'

module DocusignRest
  require_relative "docusign_rest/railtie" if defined?(Rails)

  extend Configuration
end
