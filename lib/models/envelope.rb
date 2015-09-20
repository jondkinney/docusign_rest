module Docusign
  class Envelope
    attr_accessor :recipients, :template_ids, :id, :docusign_client

    def initialize(options={})
      @template_ids = options[:template_ids]
      @recipients = options[:recipients]
      @docusign_client = DocusignRest::Client.new
    end

    def create_draft_envelope!
      @id = docusign_client.create_envelope_from_composite_template({
        status: 'created',
        body: 'Please sign these forms',
        subject: 'Please sign these forms',
        server_template_ids: template_ids,
        signers: recipients.map(&:to_h)
      })['envelopeId']
    end

    def update_tabs!
      recipients.each do |recipient|
        updater = TabsUpdater.new(id, recipient.id)
        recipient.tabs.each { |label,value| updater.set(label, value) }  if recipient.tabs.present?
        updater.execute!
      end
    end

    def send_envelope!
      create_draft_envelope!
      update_tabs!
      docusign_client.send_envelope(id)
      { envelope_id: id }
    end

    def recipient_view(recipient_id, return_url='http://www.google.com')
      recipient = recipients.find { |recipient| recipient.id == recipient_id }
      unless recipient.nil?
        docusign_client.get_recipient_view(envelope_id: id, name: recipient.name, email: recipient.email, return_url: return_url)['url']
      end
    end

  private

    def text_tab_updates(tab_ids, recipient)
      result = []
      recipient.tabs.each do |label, value|
        tab = tab_ids[label]
        next  unless tab.present?
        result << { tabId: tab_id, value: value, locked: true }
      end  if recipient.tabs.present?
      result
    end

  end
end
