module DocusignRest

  class Client
    # Define the same set of accessors as the DocusignRest module
    attr_accessor *Configuration::VALID_CONFIG_KEYS
    attr_accessor :docusign_authentication_headers, :acct_id

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


    # Internal: sets the default request headers allowing for user overrides
    # via options[:headers] from within other requests. Additionally injects
    # the X-DocuSign-Authentication header to authorize the request.
    #
    # Client can pass in header options to any given request:
    # headers: {"Some-Key" => "some/value", "Another-Key" => "another/value"}
    #
    # Then we pass them on to this method to merge them with the other
    # required headers
    #
    # Example:
    #
    #   headers(options[:headers])
    #
    # Returns a merged hash of headers overriding the default Accept header if
    # the user passes in a new "Accept" header key and adds any other
    # user-defined headers along with the X-DocuSign-Authentication headers
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
    # url - a relative url requiring a leading forward slash
    #
    # Example:
    #
    #   build_uri("/login_information")
    #
    # Returns a parsed URI object
    def build_uri(url)
      URI.parse("#{DocusignRest.endpoint}/#{DocusignRest.api_version}#{url}")
    end


    # Internal: configures Net:HTTP with some default values that are required
    # for every request to the DocuSign API
    #
    # Returns a configured Net::HTTP object into which a request can be passed
    def initialize_net_http_ssl(uri)
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
      http = initialize_net_http_ssl(uri)
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
    # email     - the email of the signer
    # name      - the name of the signer
    #
    # Returns a hash of users that need to sign the document
    def get_signers(signers)
      doc_signers = []
      signers.each_with_index do |signer, index|
        doc_signers << "{
          \"email\"       : \"#{signer[:email]}\",
          \"name\"        : \"#{signer[:name]}\",
          \"recipientId\" : \"#{index+1}\"
        }"
      end
      doc_signers.join(",")
    end


    # Internal: takes in an array of hashes of signers and concatenates all the
    # hashes with commas
    #
    # email     - the email of the signer
    # name      - the name of the signer
    # role_name - the role name of the signer ('Attorney', 'Client', etc.).
    #
    # Returns a hash of users that need to be embedded in the template to
    # create an envelope
    def get_template_roles(template_roles)
      the_template_roles = []
      template_roles.each_with_index do |role, index|
        the_template_roles << "{
          \"email\"    : \"#{role[:email]}\",
          \"name\"     : \"#{role[:name]}\",
          \"roleName\" : \"#{role[:role_name]}\"
        }"
      end
      the_template_roles.join(",")
    end


    # Internal: takes an array of hashes of signers required to complete a
    # document and allows for setting several options. Not all options are
    # currently configurable but that's easy to chnage/add which I (and I'm
    # sure others) will be doing in the future.
    #
    # email_notification - doesn't seem to stop the emails though
    # role_name          - the signer's role, like 'Attorney' or 'Client', etc.
    # template_locked    - doesn't seem to work/do anything
    # template_required  - doesn't seem to work/do anything
    # email              - the signer's email
    # name               - the signer's name
    # anchor_string      - the string of text to anchor the 'sign here' tab to
    # document_id        - if the doc you want signed isn't the first doc in
    #                      the files options hash
    # x_position         - distance horizontally from the anchor string for the
    #                      'sign here' tab to appear. Note: doesn't seem to
    #                      currently work.
    # y_position         - distance vertically from the anchor string for the
    #                      'sign here' tab to appear. Note: doesn't seem to
    #                      currently work.
    # sign_here_tab_text - instead of 'sign here'. Note: doesn't work
    # tab_label          - TODO: figure out what this is
    def get_template_signers(signers)
      doc_signers = []
      signers.each_with_index do |signer, index|
        doc_signers << "{
          \"accessCode\":\"\",
          \"addAccessCodeToEmail\":false,
          \"clientUserId\":\"\",
          \"customFields\":null,
          \"emailNotification\":#{signer[:email_notification] || 'null'},
          \"idCheckConfigurationName\":null,
          \"idCheckInformationInput\":null,
          \"inheritEmailNotificationConfiguration\":false,
          \"note\":\"\",
          \"phoneAuthentication\":null,
          \"recipientAttachments\":null,
          \"recipientId\":\"#{index+1}\",
          \"requireIdLookup\":false,
          \"roleName\":\"#{signer[:role_name]}\",
          \"routingOrder\":1,
          \"socialAuthentications\":null,
          \"templateAccessCodeRequired\":false,
          \"templateLocked\":#{signer[:template_locked] || 'false'},
          \"templateRequired\":#{signer[:template_required] || 'false'},
          \"email\":\"#{signer[:email]}\",
          \"name\":\"#{signer[:name]}\",
          \"autoNavigation\":false,
          \"defaultRecipient\":false,
          \"signatureInfo\":null,
          \"tabs\":{
            \"approveTabs\":null,
            \"checkboxTabs\":null,
            \"companyTabs\":null,
            \"dateSignedTabs\":null,
            \"dateTabs\":null,
            \"declineTabs\":null,
            \"emailTabs\":null,
            \"envelopeIdTabs\":null,
            \"fullNameTabs\":null,
            \"initialHereTabs\":null,
            \"listTabs\":null,
            \"noteTabs\":null,
            \"numberTabs\":null,
            \"radioGroupTabs\":null,
            \"signHereTabs\":[
              {
                \"anchorString\":\"#{signer[:anchor_string]}\",
                \"conditionalParentLabel\":null,
                \"conditionalParentValue\":null,
                \"documentId\":\"#{signer[:document_id] || '1'}\",
                \"pageNumber\":\"1\",
                \"recipientId\":\"#{index+1}\",
                \"templateLocked\":#{signer[:template_locked] || 'false'},
                \"templateRequired\":#{signer[:template_required] || 'false'},
                \"xPosition\":\"#{signer[:x_position] || '0'}\",
                \"yPosition\":\"#{signer[:y_position] || '0'}\",
                \"name\":\"#{signer[:sign_here_tab_text] || 'Sign Here'}\",
                \"optional\":false,
                \"scaleValue\":1,
                \"tabLabel\":\"#{signer[:tab_label] || 'Signature 1'}\"
              }
            ],
            \"signerAttachmentTabs\":null,
            \"ssnTabs\":null,
            \"textTabs\":null,
            \"titleTabs\":null,
            \"zipTabs\":null
          }
        }"
      end
      doc_signers.join(",")
    end


    # Internal: sets up the file ios array
    #
    # files - a hash of file params
    #
    # Returns the properly formatted ios used to build the file_params hash
    def create_file_ios(files)
      # UploadIO is from the multipart-post gem's lib/composite_io.rb:57
      # where it has this documentation:
      #
      # ********************************************************************
      # Create an upload IO suitable for including in the params hash of a
      # Net::HTTP::Post::Multipart.
      #
      # Can take two forms. The first accepts a filename and content type, and
      # opens the file for reading (to be closed by finalizer).
      #
      # The second accepts an already-open IO, but also requires a third argument,
      # the filename from which it was opened (particularly useful/recommended if
      # uploading directly from a form in a framework, which often save the file to
      # an arbitrarily named RackMultipart file in /tmp).
      #
      # Usage:
      #
      #     UploadIO.new("file.txt", "text/plain")
      #     UploadIO.new(file_io, "text/plain", "file.txt")
      # ********************************************************************
      #
      # There is also a 4th undocumented argument, opts={}, which allows us
      # to send in not only the Content-Disposition of 'file' as required by
      # DocuSign, but also the documentId parameter which is required as well
      #
      ios = []
      files.each_with_index do |file, index|
        ios << UploadIO.new(
                 file[:io] || file[:path],
                 file[:content_type] || "application/pdf",
                 file[:name],
                 "Content-Disposition" => "file; documentid=#{index+1}"
               )
      end
      ios
    end


    # Internal: sets up the file_params for inclusion in a multipart post request
    #
    # ios - an array of UploadIO formatted file objects
    #
    # Returns a hash of files params suitable for inclusion in a multipart
    # post request
    def create_file_params(ios)
      # multi-doc uploading capabilities, each doc needs to be it's own param
      file_params = {}
      ios.each_with_index do |io,index|
        file_params.merge!("file#{index+1}" => io)
      end
      file_params
    end


    # Internal: takes in an array of hashes of documents and calculates the
    # documentId then concatenates all the hashes with commas
    #
    # Returns a hash of documents that are to be uploaded
    def get_documents(ios)
      documents = []
      ios.each_with_index do |io, index|
        documents << "{
          \"documentId\" : \"#{index+1}\",
          \"name\"       : \"#{io.original_filename}\"
        }"
      end
      documents.join(",")
    end


    # Internal sets up the Net::HTTP request
    #
    # uri         - the fully qualified final URI
    # post_body   - the custom post body including the signers, etc
    # file_params - formatted hash of ios to merge into the post body
    # options     - allows for passing in custom headers
    #
    # Returns a request opbject suitable for embedding in a request
    def initialize_net_http_multipart_post_request(uri, post_body, file_params, headers)
      # Net::HTTP::Post::Multipart is from the multipart-post gem's lib/multipartable.rb
      #
      # path       - the fully qualified URI for the request
      # params     - a hash of params (including files for uploading and a
      #              customized request body)
      # headers={} - the fully merged, final request headers
      # boundary   - optional: you can give the request a custom boundary
      #
      request = Net::HTTP::Post::Multipart.new(
        uri.request_uri,
        {post_body: post_body}.merge(file_params),
        headers
      )

      # DocuSign requires that we embed the document data in the body of the
      # JSON request directly so we need to call ".read" on the multipart-post
      # provided body_stream in order to serialize all the files into a
      # compatible JSON string.
      request.body = request.body_stream.read
      request
    end


    # Public: creates an envelope from a document directly without a template
    #
    # file_io       - optional: an opened file stream of data (if you don't
    #                 want to save the file to the filesystem as an incremental
    #                 step)
    # file_path     - required if you don't provide a file_io stream, this is
    #                 the local relative path of the file you wish to upload
    # file_name     - the name you want to give to the file you are uploading
    # content_type  - (for the request body) application/json is what DocuSign
    #                 is expecting
    # email_subject - (optional) short subject line for the email
    # email_body    - (optional) custom text that will be injected into the
    #                 DocuSign generated email
    # signers       - a hash of users who should receive the document and need
    #                 to sign it
    # status        - options include: 'sent', 'created', 'voided' and determine
    #                 if the envelope is sent out immediately or stored for
    #                 sending at a later time
    # headers       - allows a client to pass in some
    #
    # Returns a response object containing:
    #   envelopeId     - The envelope's ID
    #   status         - Sent, created, voided
    #   statusDateTime - The date/time the envelope was created
    #   uri            - The relative envelope uri
    def create_envelope_from_document(options={})
      ios = create_file_ios(options[:files])
      file_params = create_file_params(ios)

      post_body = "{
        \"emailBlurb\"   : \"#{options[:email][:body] if options[:email]}\",
        \"emailSubject\" : \"#{options[:email][:subject] if options[:email]}\",
        \"documents\"    : [#{get_documents(ios)}],
        \"recipients\"   : {
          \"signers\" : [#{get_signers(options[:signers])}]
        },
        \"status\"       : \"#{options[:status]}\"
      }
      "

      uri = build_uri("/accounts/#{@acct_id}/envelopes")

      http = initialize_net_http_ssl(uri)

      request = initialize_net_http_multipart_post_request(
                  uri, post_body, file_params, headers(options[:headers])
                )

      # Finally do the Net::HTTP request!
      http.request(request)
    end


    # Public: allows a template to be dynamically created with several options.
    #
    # files         - an array of hashes of file parameters which will be used
    #                 to create actual files suitable for upload in a multipart
    #                 request.
    #
    #                 Options: io, path, name. The io is optional and would
    #                 require creating a file_io object to embed as the first
    #                 argument of any given file hash. See the create_file_ios
    #                 method definition above for more details.
    #
    # email/body    - (optional) sets the text in the email. Note: the envelope
    #                 seems to override this, not sure why it needs to be
    #                 configured here as well. I usually leave it blank.
    # email/subject - (optional) sets the text in the email. Note: the envelope
    #                 seems to override this, not sure why it needs to be
    #                 configured here as well. I usually leave it blank.
    # signers       - an array of hashes of signers. See the
    #                 get_template_signers method definition for options.
    # description   - the template description
    # name          - the template name
    # headers       - optional hash of headers to merge into the existing
    #                 required headers for a multipart request.
    #
    def create_template(options={})
      ios = create_file_ios(options[:files])
      file_params = create_file_params(ios)

      post_body = "{
        \"emailBlurb\"   : \"#{options[:email][:body] if options[:email]}\",
        \"emailSubject\" : \"#{options[:email][:subject] if options[:email]}\",
        \"documents\"    : [#{get_documents(ios)}],
        \"recipients\"   : {
          \"signers\"    : [#{get_template_signers(options[:signers])}]
        },
        \"envelopeTemplateDefinition\" : {
          \"description\" : \"#{options[:description]}\",
          \"name\"        : \"#{options[:name]}\",
          \"pageCount\"   : 1,
          \"password\"    : \"\",
          \"shared\"      : false
        }
      }
      "

      uri = build_uri("/accounts/#{@acct_id}/templates")

      http = initialize_net_http_ssl(uri)

      request = initialize_net_http_multipart_post_request(
                  uri, post_body, file_params, headers(options[:headers])
                )

      # Finally do the Net::HTTP request!
      http.request(request)
    end


    # Public: create an envelope for delivery from a template
    #
    # headers        - optional hash of headers to merge into the existing
    #                  required headers for a POST request.
    # status         - options include: 'sent', 'created', 'voided' and
    #                  determine if the envelope is sent out immediately or
    #                  stored for sending at a later time
    # email/body     - sets the text in the email body
    # email/subject  - sets the text in the email subject line
    # template_id    - the id of the template upon which we want to base this
    #                  envelope
    # template_roles - see the get_template_roles method definition for a list
    #                  of options to pass
    def create_envelope_from_template(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      post_body = "{
        \"status\"        : \"#{options[:status]}\",
        \"emailBlurb\"    : \"#{options[:email][:body]}\",
        \"emailSubject\"  : \"#{options[:email][:subject]}\",
        \"templateId\"    : \"#{options[:template_id]}\",
        \"templateRoles\" : [#{get_template_roles(options[:template_roles])}],
       }"

      uri = build_uri("/accounts/#{@acct_id}/envelopes")

      http = initialize_net_http_ssl(uri)

      request = Net::HTTP::Post.new(
                  uri.request_uri,
                  headers(content_type)
                )
      request.body = post_body

      http.request(request)
    end


    # Public returns the URL for embedded signing
    #
    # email      - the email of the recipient
    # return_url - the URL you want the user to be directed to after he or she
    #              completes the document signing
    # user_name  - the name of the signer
    #
    # Returns the URL for embedded signing which needs to be put in an iFrame
    def get_recipient_view(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      post_body = "{
        \"authenticationMethod\" : \"email\",
        \"email\"                : \"#{options[:email]}\",
        \"returnUrl\"            : \"#{options[:return_url]}\",
        \"userName\"             : \"#{options[:user_name]}\",
       }"

      uri = build_uri("/accounts/#{@acct_id}/envelopes/#{options[:envelope_id]}/views/recipient")

      http = initialize_net_http_ssl(uri)

      request = Net::HTTP::Post.new(
                  uri.request_uri,
                  headers(content_type)
                )
      request.body = post_body

      http.request(request)
    end

  end

end
