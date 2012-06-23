require 'docusign_rest/version'
require 'docusign_rest/configuration'
require 'docusign_rest/client'
require 'docusign_rest/utility'
require 'multipart_post' #require the multipart-post gem itself
require 'net/http/post/multipart' #require the multipart-post net/http/post/multipart monkey patch
require 'multipart_post/parts' #require my monkey patched parts.rb which adjusts the build_part method
require 'net/http'
require 'json'

module DocusignRest
  require "docusign_rest/railtie" if defined?(Rails)

  extend Configuration
end
