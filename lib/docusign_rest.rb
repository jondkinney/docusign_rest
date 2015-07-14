require_relative 'docusign_rest/version'
require_relative 'docusign_rest/configuration'
require_relative 'docusign_rest/client'
require_relative 'docusign_rest/utility'
require 'multipart_post' #require the multipart-post gem itself
require 'net/http/post/multipart' #require the multipart-post net/http/post/multipart monkey patch
require 'net/http'
require 'json'

module DocusignRest
  require_relative "docusign_rest/railtie" if defined?(Rails)

  extend Configuration
end
