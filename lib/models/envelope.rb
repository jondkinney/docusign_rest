module Docusign

  class InvalidRecipientId < StandardError; end

  class Envelope
    attr_accessor :id, :docusign_client, :email, :composite_templates

    def initialize(composite_templates: nil, email: nil)
      @email = email
      @composite_templates = composite_templates
      @docusign_client = DocusignRest::Client.new
    end

    def create_envelope!
      @id = docusign_client.create_envelope(self)[:envelopeId]
      { envelope_id: id }
    end

    def to_h
      {
        status: 'sent',
        emailSubject: email.andand[:subject],
        compositeTemplates: composite_templates.andand.map(&:to_h)
      }
    end
  end
end
