module Docusign
  class TabsUpdater
    attr_accessor :envelope_id, :recipient_id, :docusign_client

    def initialize(envelope_id, recipient_id)
      @docusign_client = DocusignRest::Client.new
      @envelope_id = envelope_id
      @recipient_id = recipient_id
      @lookup = {}
      retrieve_tabs
    end

    def set(label, value)
      @lookup[label].value = value  unless @lookup[label].nil?
    end

    def [](label)
      @lookup[label]
    end

    def execute!
      updates = @lookup.values.
        select { |tab| tab.dirty? }.
        group_by { |tab| tab.class.collection_name }

      docusign_client.modify_tabs(envelope_id, recipient_id, updates)  if updates.present?
    end

  private

    def retrieve_tabs
      metadata = docusign_client.retrieve_tabs(envelope_id, recipient_id)
      metadata.each do |collection_type, tabs|
        tab_class = Tab.class_for(collection_type)
        tabs.each do |tab|
          label = tab[:tabLabel]
          @lookup[label] = tab_class.new(id: tab[:tabId], label: label)
        end
      end  unless metadata.nil?
    end
  end
end
