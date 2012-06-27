require 'helper'

describe DocusignRest::Client do

  before do
    @keys = DocusignRest::Configuration::VALID_CONFIG_KEYS
  end

  describe 'with module configuration' do
    before do
      DocusignRest.configure do |config|
        @keys.each do |key|
          config.send("#{key}=", key)
        end
      end
    end

    after do
      DocusignRest.reset
    end

    it "should inherit module configuration" do
      api = DocusignRest::Client.new
      @keys.each do |key|
        api.send(key).must_equal key
      end
    end

    describe 'with class configuration' do
      before do
        @config = {
          :username       => 'un',
          :password       => 'pd',
          :integrator_key => 'ik',
          :account_id     => 'ai',
          :format         => 'fm',
          :endpoint       => 'ep',
          :api_version    => 'av',
          :user_agent     => 'ua',
          :method         => 'md',
        }
      end

      it 'should override module configuration' do
        api = DocusignRest::Client.new(@config)
        @keys.each do |key|
          api.send(key).must_equal @config[key]
        end
      end

      it 'should override module configuration after' do
        api = DocusignRest::Client.new

        @config.each do |key, value|
          api.send("#{key}=", value)
        end

        @keys.each do |key|
          api.send("#{key}").must_equal @config[key]
        end
      end
    end
  end

  describe 'client' do
    before do
      # Note: to configure the client please run the docusign_task.rb file:
      #
      #     $ ruby lib/tasks/docusign_task.rb
      #
      # which will populate the test/docusign_login_config.rb file
      @client = DocusignRest::Client.new
    end

    it "should allow access to the auth headers after initialization" do
      @client.must_respond_to :docusign_authentication_headers
    end

    it "should allow access to the acct_id after initialization" do
      @client.must_respond_to :acct_id
    end

    it "should allow creating an envelope from a document" do
      VCR.use_cassette("create_envelope/from_document", record: :all) do
        response = @client.create_envelope_from_document(
          email: {
            subject: "test email subject",
            body: "this is the email body and it's large!"
          },
          # If embedded is set to true  in the signers array below, emails
          # don't go out and you can embed the signature page in an iFrame
          # by using the get_recipient_view method. You can choose 'false' or
          # simply omit the option as I show in the second signer hash.
          signers: [
            {
              embedded: true,
              name: 'Test Guy',
              email: 'someone@gmail.com'
            },
            {
              #embedded: true,
              name: 'Test Girl',
              email: 'someone+else@gmail.com'
            }
          ],
          files: [
            {path: 'test.pdf', name: 'test.pdf'},
            {path: 'test2.pdf', name: 'test2.pdf'}
          ],
          status: 'sent'
        )
        response["status"].must_equal "sent"
      end
    end

    describe "embedded signing" do
      before do
        # create the template dynamically
        VCR.use_cassette("create_template", record: :all)  do
          @template_response = @client.create_template(
            description: 'Cool Description',
            name: "Cool Template Name",
            signers: [
              {
                embedded: true,
                name: 'jon',
                email: 'someone@gmail.com',
                role_name: 'Issuer',
                anchor_string: 'sign here',
                template_locked: true, #doesn't seem to do anything
                template_required: true, #doesn't seem to do anything
                email_notification: false #FIXME if signer is setup as 'embedded' initial email notifications don't go out, but even when I set up a signer as non-embedded this setting didn't seem to make the email notifications actually stop...
              }
            ],
            files: [
              {path: 'test.pdf', name: 'test.pdf'}
            ]
          )
        end

        # use the templateId to get the envelopeId
        VCR.use_cassette("create_envelope/from_template", record: :all)  do
          @envelope_response = @client.create_envelope_from_template(
            status: 'sent',
            email: {
              subject: "The test email subject envelope",
              body: "Envelope body content here"
            },
            template_id: @template_response["templateId"],
            signers: [
              {
                embedded: true,
                name: 'jon',
                email: 'someone@gmail.com',
                role_name: 'Issuer'
              }
            ]
          )
        end
      end

      it "should return a URL for embedded signing" do
        #ensure template was created
        @template_response["templateId"].wont_be_nil
        @template_response["name"].must_equal "Cool Template Name"

        #ensure creating an envelope from a dynamic template did not error
        @envelope_response["errorCode"].must_be_nil

        #return the URL for embedded signing
        VCR.use_cassette("get_recipient_view", record: :all)  do
          response = @client.get_recipient_view(
            envelope_id: @envelope_response["envelopeId"],
            name: 'jon',
            email: 'someone@gmail.com',
            return_url: 'http://google.com'
          )
          response.must_match(/http/)
        end
      end

      #status return values = "sent", "delivered", "completed"
      it "should retrieve the envelope recipients status" do
        VCR.use_cassette("get_envelope_recipients", record: :all)  do
          response = @client.get_envelope_recipients(
            envelope_id: @envelope_response["envelopeId"],
            include_tabs: true,
            include_extended: true
          )
          response["signers"].wont_be_nil
          #puts response["signers"]
        end
      end

      #status return values = "sent", "delivered", "completed"
      it "should retrieve the byte stream of the envelope doc from DocuSign" do
        VCR.use_cassette("get_document_from_envelope", record: :all)  do
          @client.get_document_from_envelope(
            envelope_id: @envelope_response["envelopeId"],
            document_id: 1,
            local_save_path: 'docusign_docs/file_name.pdf'
          )
          # NOTE manually check that this file has the content you'd expect
        end
      end

    end

  end

end
