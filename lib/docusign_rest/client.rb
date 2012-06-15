module DocusignRest

  class Client
    # Define the same set of accessors as the DocusignRest module
    attr_accessor *Configuration::VALID_CONFIG_KEYS

    def initialize(options={})
      # Merge the config values from the module and those passed to the client.
      merged_options = DocusignRest.options.merge(options)

      # Copy the merged values to this client and ignore those not part
      # of our configuration
      Configuration::VALID_CONFIG_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end

      # Set up the Docusign Authentication headers with the values passed from
      # our config block
      @docusign_authentication_headers = {
        "X-DocuSign-Authentication" => "" \
          "<DocuSignCredentials>" \
            "<Username>#{DocusignRest.username}</Username>" \
            "<Password>#{DocusignRest.password}</Password>" \
            "<IntegratorKey>#{DocusignRest.integrator_key}</IntegratorKey>" \
          "</DocuSignCredentials>"
      }

      # Set the account_id from the configure block if present, but can't call
      # the instance var @account_id because that'll override the attr_accessor
      # that is automatically configured for the configure block
      @acct_id = DocusignRest.account_id
    end

    # Public: sets the default request headers allowing for user overrides.
    # Additionally injects the X-DocuSign-Authentication header to authorize
    # the request.
    #
    # Example:
    #
    #   headers("Some-Key" => "some/value", "Another-Key" => "another/value")
    #
    # Returns a merged hash of headers overriding the default Accept header if
    # the user passes in a new "Accept" header key.
    def headers(user_defined_headers={})
      default = {
        "Accept" => "application/json" #this seems to get added automatically, so I can probably remove this
      }

      default.merge!(user_defined_headers) if user_defined_headers

      @docusign_authentication_headers.merge(default)
    end

    # Internal: builds a URI based on the configurable endpoint, api_version,
    # and the passed in relative url
    #
    # Returns a parsed URI
    def build_uri(url)
      URI.parse("#{DocusignRest.endpoint}/#{DocusignRest.api_version}#{url}")
    end

    # Internal: configures Net:HTTP with some default values that are required
    # for every request to the DocuSign API
    #
    # Returns a configured Net::HTTP object into which a request can be passed
    def initialize_net_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end

    # Public: gets info necessary to make addtl requests to the DocuSign API
    #
    # options - hash of headers if the client wants to override something
    #
    # Examples:
    #
    #   client = DocusignRest::Client.new
    #   response = client.login_information
    #   puts response.body
    #
    # Returns:
    #   accountId - For the username, password, and integrator_key specified
    #   baseUrl   - The base URL for all future DocuSign requests
    #   email     - The email used when signing up for DocuSign
    #   isDefault - # TODO identify what this is
    #   name      - The account name provided when signing up for DocuSign
    #   userId    - # TODO determine what this is used for, if anything
    #   userName  - Full name provided when signing up for DocuSign
    def get_login_information(options={})
      uri = build_uri("/login_information")
      request = Net::HTTP::Get.new(uri.request_uri, headers(options[:headers]))
      http = initialize_net_http(uri)
      http.request(request)
    end

    # Internal: uses the get_login_information method to determine the client's
    # accountId and then caches that value into an instance variable so we
    # don't end up hitting the api for login_information more than once per
    # request.
    #
    # This is used by the rake task in lib/tasks/docusign_task.rake to add
    # the config/initialzers/docusign_rest.rb file with the proper config block
    # which includes the account_id in it. That way we don't require hitting
    # the /login_information URI in normal requests
    #
    # Returns the accountId string
    def get_account_id
      unless @acct_id
        response = get_login_information.body
        hashed_response = JSON.parse(response)
        login_accounts = hashed_response['loginAccounts']
        @acct_id ||= login_accounts.first['accountId']
      end

      @acct_id
    end

    # Internal: takes in an array of hashes of signers and calculates the
    # recipientId then concatenates all the hashes with commas
    #
    # Returns a hash of users that need to sign the document
    def get_signers(signers)
      doc_signers = []
      signers.each_with_index do |signer, index|
        doc_signers << "{
            \"email\": \"#{signer[:email]}\",
            \"name\": \"#{signer[:name]}\",
            \"recipientId\": \"#{index+1}\"
        }"
      end
      doc_signers.join(",")
    end

    # Internal: takes in an array of hashes of documents and calculates the
    # documentId then concatenates all the hashes with commas
    #
    # Returns a hash of documents that are to be uploaded
    def get_documents(ios)
      documents = []
      ios.each_with_index do |io, index|
        documents << "{
          \"documentId\": \"#{index+1}\",
          \"name\": \"#{io.original_filename}\"
        }"
      end
      documents.join(",")
    end

    # Public: creates an envelope from a document directly without a template
    #
    # file_path     - the local relative path of the file you wish to upload
    # file_name     - the name you want to give to the file you are uploading
    # content_type  - application/json or application/csv, etc.
    # email_subject - short subject line for the email
    # email_body    - custom text that will be injected into the DocuSign
    #                 generated email
    # signers       - a hash of users who should receive the document and need
    #                 to sign it
    # status        - options include: 'sent', 'draft' and determine if the
    #                 envelope is sent out immediately or stored for sending
    #                 at a later time
    #
    # Returns a response object containing:
    #   envelopeId     - The envelope's ID
    #   status         - Sent, draft, etc
    #   statusDateTime - The date/time the envelope was created
    #   uri            - The relative envelope uri
    def create_envelope_from_document(options={})
      # the last argument is the opts={} which allows us to send in not only
      # the Content-Disposition of 'file' as required by DocuSign, but also
      # the documentId parameter which is required as well

      ios = []
      options[:files].each_with_index do |file, index|
        ios << UploadIO.new(
          file[:path],
          file[:content_type] || "application/pdf",
          file[:name],
          "Content-Disposition" => "file; documentid=#{index+1}"
        )
      end

      post_body = "{
        \"emailBlurb\": \"#{options[:email][:body]}\",
        \"emailSubject\": \"#{options[:email][:subject]}\",
        \"documents\": [#{get_documents(ios)}],
        \"recipients\": {
          \"signers\": [#{get_signers(options[:signers])}]
        },
        \"status\": \"#{options[:status]}\"
      }
      "

      uri = build_uri("/accounts/#{@acct_id}/envelopes")

      # TODO see if there is a way to upload multiple documents in Net::HTTP
      # becuase currently we're calling .first on the ios array of docs
      request = Net::HTTP::Post::Multipart.new(
        uri.request_uri,
        {post_body: post_body, file: ios.first},
        headers(options[:headers])
      )
      request.body = request.body_stream.read

      http = initialize_net_http(uri)
      http.request(request)
    end

  end

end
