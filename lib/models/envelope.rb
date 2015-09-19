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
        tabs_metadata = docusign_client.retrieve_tabs(id, recipient.id)

        tab_ids = tab_ids(tabs_metadata)
        text_tab_updates = text_tab_updates(tab_ids, recipient)

        unless text_tab_updates.empty?
          docusign_client.modify_tabs(id, recipient.id, { textTabs: text_tab_updates })
        end
      end
    end

    def send_envelope!
      create_draft_envelope!
      update_tabs!
      docusign_client.send_envelope(id)
      { envelope_id: id }
    end

  private

    # creates tab_id lookup map for a tab_label
    def tab_ids(tabs_metadata)
      result = {}
      tabs_metadata[:textTabs].each do |textTab|
        label = textTab[:tabLabel].to_sym
        result[label] = textTab[:tabId]
      end  if tabs_metadata.andand[:textTabs].present?
      result
    end

    def text_tab_updates(tab_ids, recipient)
      result = []
      recipient.tabs.each do |label, value|
        tab_id = tab_ids[label]
        next  unless tab_id.present?
        result << { tabId: tab_id, value: value, locked: true }
      end  if recipient.tabs.present?
      result
    end

  end
end
