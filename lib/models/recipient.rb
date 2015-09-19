module Docusign

  class Recipient
    attr_accessor :id, :role_name, :name, :email, :tabs, :embedded

    def initialize(options={})
      @id = options[:id]
      @role_name = options[:role_name]
      @name = options[:name]
      @email = options[:email]
      @tabs = options[:tabs]
      @embedded = options[:embedded] || true
    end

    def to_h
      {
        recipient_id: id,
        role_name: role_name,
        name: name,
        email: email,
        tabs: tabs,
        embedded: embedded
      }
    end

    def self.merge(recipients)
      recipients.sort_by { |recipient| recipient.id }
        .group_by { |recipient| recipient.role_name }
        .values
        .map { |recipients| merge_tabs(recipients) }
    end

  private

    def self.merge_tabs(recipients)
      result = recipients.first.dup
      result.tabs = {}

      recipients.each do |recipient|
        result.tabs.merge!(recipient.tabs)  if recipient.tabs.present?
      end
      result.tabs = nil  if result.tabs.empty?
      result
    end
  end
end
