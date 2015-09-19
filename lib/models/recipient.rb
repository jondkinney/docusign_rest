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
  end

end
