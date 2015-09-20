module Docusign
  class TabsUpdater
    attr_accessor :docusign_client

    def initialize(envelope_id, recipient_id)
      @envelope_id = envelope_id
      @recipient_id = recipient_id
      @docusign_client = DocusignRest::Client.new
      @tabs = tabs
    end

    def set(label, value)
      label = label.to_s
      @tabs[label].value = value  if @tabs[label].present?
      @tabs[label]
    end

    def [](label)
      @tabs[label]
    end

    def execute!
      updates = @tabs.values.
        select { |tab| tab.dirty? }.
        group_by { |tab| tab.collection_name }.
        reduce({}) { |result, (name,tabs)| result[name] = tabs.map(&:to_h); result }

      @docusign_client.modify_tabs(@envelope_id, @recipient_id, updates)  if updates.present?
    end

  private

    def class_for(collection_name)
      name = collection_name.to_s.singularize.camelize
      "Docusign::#{name}".constantize
    rescue => e
    end

    def tabs
      metadata = @docusign_client.retrieve_tabs(@envelope_id, @recipient_id)
      return {}  unless metadata.present?

      metadata.reduce({}) do |result, (collection_name, tabs)|
        tab_class = class_for(collection_name)
        tabs.each do |tab|
          label = tab[:tabLabel].to_s
          result[label] = tab_class.new(id: tab[:tabId], label: label)
        end  unless tab_class.nil?
        result
      end
    end

  end
end
