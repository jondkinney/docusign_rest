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

      # Set up the DocuSign Authentication headers with the values passed from
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

      # Explicitly verifies that the certificate matches the domain. Requires
      # that we use www when calling the production DocuSign API
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      http
    end


    # Public: gets info necessary to make additional requests to the DocuSign API
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
    # don't end up hitting the API for login_information more than once per
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


    def check_embedded_signer(embedded, email)
      if embedded && embedded == true
        "\"clientUserId\" : \"#{email}\","
      end
    end


    # Internal: takes in an array of hashes of signers and concatenates all the
    # hashes with commas
    #
    # embedded -  Tells DocuSign if this is an embedded signer which determines
    #             weather or not to deliver emails. Also lets us authenticate
    #             them when they go to do embedded signing. Behind the scenes
    #             this is setting the clientUserId value to the signer's email.
    # name      - The name of the signer
    # email     - The email of the signer
    # role_name - The role name of the signer ('Attorney', 'Client', etc.).
    #
    # Returns a hash of users that need to be embedded in the template to
    # create an envelope
    def get_template_roles(signers)
      template_roles = []
      signers.each_with_index do |signer, index|
        template_roles << "{
          #{check_embedded_signer(signer[:embedded], signer[:email])}
          \"name\"         : \"#{signer[:name]}\",
          \"email\"        : \"#{signer[:email]}\",
          \"roleName\"     : \"#{signer[:role_name]}\"
        }"
      end
      template_roles.join(",")
    end


    # Internal: takes an array of hashes of signers required to complete a
    # document and allows for setting several options. Not all options are
    # currently dynamic but that's easy to change/add which I (and I'm
    # sure others) will be doing in the future.
    #
    # template           - Includes other optional fields only used when
    #                      being called from a template
    # email              - The signer's email
    # name               - The signer's name
    # embedded           - Tells DocuSign if this is an embedded signer which
    #                      determines weather or not to deliver emails. Also
    #                      lets us authenticate them when they go to do
    #                      embedded signing. Behind the scenes this is setting
    #                      the clientUserId value to the signer's email.
    # email_notification - Send an email or not
    # role_name          - The signer's role, like 'Attorney' or 'Client', etc.
    # template_locked    - Doesn't seem to work/do anything
    # template_required  - Doesn't seem to work/do anything
    # anchor_string      - The string of text to anchor the 'sign here' tab to
    # document_id        - If the doc you want signed isn't the first doc in
    #                      the files options hash
    # page_number        - Page number of the sign here tab
    # x_position         - Distance horizontally from the anchor string for the
    #                      'sign here' tab to appear. Note: doesn't seem to
    #                      currently work.
    # y_position         - Distance vertically from the anchor string for the
    #                      'sign here' tab to appear. Note: doesn't seem to
    #                      currently work.
    # sign_here_tab_text - Instead of 'sign here'. Note: doesn't work
    # tab_label          - TODO: figure out what this is
    def get_signers(signers, options={})
      doc_signers = []
      signers.each_with_index do |signer, index|
        # Build up a string with concatenation so that we can append the full
        # string to the doc_signers array as the last step in this block
        doc_signer = ""
        doc_signer << "{
          \"email\":\"#{signer[:email]}\",
          \"name\":\"#{signer[:name]}\",
          \"accessCode\":\"\",
          \"addAccessCodeToEmail\":false,
          #{check_embedded_signer(signer[:embedded], signer[:email])}
          \"customFields\":null,
          \"emailNotification\":#{signer[:email_notification] || 'null'},
          \"iDCheckConfigurationName\":null,
          \"iDCheckInformationInput\":null,
          \"inheritEmailNotificationConfiguration\":false,
          \"note\":\"\",
          \"phoneAuthentication\":null,
          \"recipientAttachment\":null,
          \"recipientId\":\"#{index+1}\",
          \"requireIdLookup\":false,
          \"roleName\":\"#{signer[:role_name]}\",
          \"routingOrder\":#{index+1},
          \"socialAuthentications\":null,
        "

        if options[:template] == true
          doc_signer << "
            \"templateAccessCodeRequired\":false,
            \"templateLocked\":#{signer[:template_locked] || true},
            \"templateRequired\":#{signer[:template_required] || true},
          "
        end

        doc_signer << "
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
          "
          signer[:sign_here_tabs].each do |sign_here_tab|
            doc_signer << "{
              \"anchorString\":\"#{sign_here_tab[:anchor_string]}\",
              \"anchorXOffset\": \"#{sign_here_tab[:anchor_x_offset] || '0'}\",
              \"anchorYOffset\": \"#{sign_here_tab[:anchor_y_offset] || '0'}\",
              \"anchorIgnoreIfNotPresent\": #{sign_here_tab[:ignore_anchor_if_not_present] || false},
              \"anchorUnits\": \"pixels\",
              \"conditionalParentLabel\": null,
              \"conditionalParentValue\": null,
              \"documentId\":\"#{sign_here_tab[:document_id] || '1'}\",
              \"pageNumber\":\"#{sign_here_tab[:page_number] || '1'}\",
              \"recipientId\":\"#{index+1}\",
            "
            if options[:template] == true
              doc_signer << "
                \"templateLocked\":#{sign_here_tab[:template_locked] || true},
                \"templateRequired\":#{sign_here_tab[:template_required] || true},
              "
            end
            doc_signer << "
              \"xPosition\":\"#{sign_here_tab[:x_position] || '0'}\",
              \"yPosition\":\"#{sign_here_tab[:y_position] || '0'}\",
              \"name\":\"#{sign_here_tab[:sign_here_tab_text] || 'Sign Here'}\",
              \"optional\":false,
              \"scaleValue\":1,
              \"tabLabel\":\"#{sign_here_tab[:tab_label] || 'Signature 1'}\"
            },"
          end
          doc_signer << "],
            \"signerAttachmentTabs\":null,
            \"ssnTabs\":null,
            \"textTabs\":null,
            \"titleTabs\":null,
            \"zipTabs\":null
          }
        }"
        # append the fully build string to the array
        doc_signers << doc_signer
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
    # ios - An array of UploadIO formatted file objects
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
    # uri         - The fully qualified final URI
    # post_body   - The custom post body including the signers, etc
    # file_params - Formatted hash of ios to merge into the post body
    # headers     - Allows for passing in custom headers
    #
    # Returns a request object suitable for embedding in a request
    def initialize_net_http_multipart_post_request(uri, post_body, file_params, headers)
      # Net::HTTP::Post::Multipart is from the multipart-post gem's lib/multipartable.rb
      #
      # path       - The fully qualified URI for the request
      # params     - A hash of params (including files for uploading and a
      #              customized request body)
      # headers={} - The fully merged, final request headers
      # boundary   - Optional: you can give the request a custom boundary
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
    # file_io       - Optional: an opened file stream of data (if you don't
    #                 want to save the file to the file system as an incremental
    #                 step)
    # file_path     - Required if you don't provide a file_io stream, this is
    #                 the local path of the file you wish to upload. Absolute
    #                 paths recommended.
    # file_name     - The name you want to give to the file you are uploading
    # content_type  - (for the request body) application/json is what DocuSign
    #                 is expecting
    # email_subject - (Optional) short subject line for the email
    # email_body    - (Optional) custom text that will be injected into the
    #                 DocuSign generated email
    # signers       - A hash of users who should receive the document and need
    #                 to sign it. More info about the options available for
    #                 this method are documented above it's method definition.
    # status        - Options include: 'sent', 'created', 'voided' and determine
    #                 if the envelope is sent out immediately or stored for
    #                 sending at a later time
    # headers       - Allows a client to pass in some
    #
    # Returns a JSON parsed response object containing:
    #   envelopeId     - The envelope's ID
    #   status         - Sent, created, or voided
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
      response = http.request(request)
      parsed_response = JSON.parse(response.body)
    end


    # Public: allows a template to be dynamically created with several options.
    #
    # files         - An array of hashes of file parameters which will be used
    #                 to create actual files suitable for upload in a multipart
    #                 request.
    #
    #                 Options: io, path, name. The io is optional and would
    #                 require creating a file_io object to embed as the first
    #                 argument of any given file hash. See the create_file_ios
    #                 method definition above for more details.
    #
    # email/body    - (Optional) sets the text in the email. Note: the envelope
    #                 seems to override this, not sure why it needs to be
    #                 configured here as well. I usually leave it blank.
    # email/subject - (Optional) sets the text in the email. Note: the envelope
    #                 seems to override this, not sure why it needs to be
    #                 configured here as well. I usually leave it blank.
    # signers       - An array of hashes of signers. See the
    #                 get_signers method definition for options.
    # description   - The template description
    # name          - The template name
    # headers       - Optional hash of headers to merge into the existing
    #                 required headers for a multipart request.
    #
    # Returns a JSON parsed response body containing the template's:
    #   name - Name given above
    #   templateId - The auto-generated ID provided by DocuSign
    #   Uri - the URI where the template is located on the DocuSign servers
    def create_template(options={})
      ios = create_file_ios(options[:files])
      file_params = create_file_params(ios)

      post_body = "{
        \"emailBlurb\"   : \"#{options[:email][:body] if options[:email]}\",
        \"emailSubject\" : \"#{options[:email][:subject] if options[:email]}\",
        \"documents\"    : [#{get_documents(ios)}],
        \"recipients\"   : {
          \"signers\"    : [#{get_signers(options[:signers], template: true)}]
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
      response = http.request(request)
      parsed_response = JSON.parse(response.body)
    end


    # Public: create an envelope for delivery from a template
    #
    # headers        - Optional hash of headers to merge into the existing
    #                  required headers for a POST request.
    # status         - Options include: 'sent', 'created', 'voided' and
    #                  determine if the envelope is sent out immediately or
    #                  stored for sending at a later time
    # email/body     - Sets the text in the email body
    # email/subject  - Sets the text in the email subject line
    # template_id    - The id of the template upon which we want to base this
    #                  envelope
    # template_roles - See the get_template_roles method definition for a list
    #                  of options to pass. Note: for consistency sake we call
    #                  this 'signers' and not 'templateRoles' when we build up
    #                  the request in client code.
    # headers        - Optional hash of headers to merge into the existing
    #                  required headers for a multipart request.
    #
    # Returns a JSON parsed response body containing the envelope's:
    #   name - Name given above
    #   templateId - The auto-generated ID provided by DocuSign
    #   Uri - the URI where the template is located on the DocuSign servers
    def create_envelope_from_template(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      post_body = "{
        \"status\"        : \"#{options[:status]}\",
        \"emailBlurb\"    : \"#{options[:email][:body]}\",
        \"emailSubject\"  : \"#{options[:email][:subject]}\",
        \"templateId\"    : \"#{options[:template_id]}\",
        \"templateRoles\" : [#{get_template_roles(options[:signers])}],
       }"

      uri = build_uri("/accounts/#{@acct_id}/envelopes")

      http = initialize_net_http_ssl(uri)

      request = Net::HTTP::Post.new(uri.request_uri, headers(content_type))
      request.body = post_body

      response = http.request(request)
      parsed_response = JSON.parse(response.body)
    end


    # Public returns the URL for embedded signing
    #
    # envelope_id - the ID of the envelope you wish to use for embedded signing
    # name        - the name of the signer
    # email       - the email of the recipient
    # return_url  - the URL you want the user to be directed to after he or she
    #               completes the document signing
    # headers     - optional hash of headers to merge into the existing
    #               required headers for a multipart request.
    #
    # Returns the URL string for embedded signing (can be put in an iFrame)
    def get_recipient_view(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      post_body = "{
        \"authenticationMethod\" : \"email\",
        \"clientUserId\"         : \"#{options[:email]}\",
        \"email\"                : \"#{options[:email]}\",
        \"returnUrl\"            : \"#{options[:return_url]}\",
        \"userName\"             : \"#{options[:name]}\",
       }"

      uri = build_uri("/accounts/#{@acct_id}/envelopes/#{options[:envelope_id]}/views/recipient")

      http = initialize_net_http_ssl(uri)

      request = Net::HTTP::Post.new(uri.request_uri, headers(content_type))
      request.body = post_body

      response = http.request(request)
      parsed_response = JSON.parse(response.body)
      parsed_response["url"]
    end

    # Public returns the envelope recipients for a given envelope
    #
    # include_tabs - boolean, determines if the tabs for each signer will be
    #                returned in the response, defaults to false.
    # envelope_id  - ID of the envelope for which you want to retrive the
    #                signer info
    # headers      - optional hash of headers to merge into the existing
    #                required headers for a multipart request.
    #
    # Returns a hash of detailed info about the envelope including the signer
    # hash and status of each signer
    def get_envelope_recipients(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      include_tabs = options[:include_tabs] || false
      include_extended = options[:include_extended] || false
      uri = build_uri("/accounts/#{@acct_id}/envelopes/#{options[:envelope_id]}/recipients?include_tabs=#{include_tabs}&include_extended=#{include_extended}")

      http = initialize_net_http_ssl(uri)
      request = Net::HTTP::Get.new(uri.request_uri, headers(content_type))
      response = http.request(request)
      parsed_response = JSON.parse(response.body)
    end

    # Public retrieves the attached file from a given envelope
    #
    # envelope_id      - ID of the envelope from which the doc will be retrieved
    # document_id      - ID of the document to retrieve
    # local_save_path  - Local absolute path to save the doc to including the
    #                    filename itself
    # headers          - Optional hash of headers to merge into the existing
    #                    required headers for a multipart request.
    #
    # Example
    #
    #   client.get_document_from_envelope(
    #     envelope_id: @envelope_response["envelopeId"],
    #     document_id: 1,
    #     local_save_path: 'docusign_docs/file_name.pdf'
    #   )
    #
    # Returns the PDF document as a byte stream.
    def get_document_from_envelope(options={})
      content_type = {'Content-Type' => 'application/json'}
      content_type.merge(options[:headers]) if options[:headers]

      uri = build_uri("/accounts/#{@acct_id}/envelopes/#{options[:envelope_id]}/documents/#{options[:document_id]}")

      http = initialize_net_http_ssl(uri)
      request = Net::HTTP::Get.new(uri.request_uri, headers(content_type))
      response = http.request(request)

      split_path = options[:local_save_path].split('/')
      split_path.pop #removes the document name and extension from the array
      path = split_path.join("/") #rejoins the array to form path to the folder that will contain the file

      FileUtils.mkdir_p(path)
      File.open(options[:local_save_path], 'wb') do |output|
        output << response.body
      end
    end

    # Public: Retrieves a list of available templates
    #
    # Example
    #
    #    client.get_templates()
    #
    # Returns a list of the available templates.
    def get_templates
      uri = build_uri("/accounts/#{@acct_id}/templates")

      http = initialize_net_http_ssl(uri)
      request = Net::HTTP::Get.new(uri.request_uri, headers({"Content-Type" => "application/json"}))
      JSON.parse(http.request(request).body)
    end
  end

end
