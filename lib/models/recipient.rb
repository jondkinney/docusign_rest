module Docusign

  class Recipient
    attr_accessor :id, :role_name, :name, :email, :tabs, :embedded

    def initialize(id: nil, role_name: nil, name: nil, email: nil, embedded: false, tabs: nil)
      @id = id
      @role_name = role_name
      @name = name
      @email = email
      @embedded = embedded
      @tabs = tabs
    end

    def to_h
      {
        recipientId: id,
        roleName: role_name,
        email: email,
        clientUserId: email,
        name: name,
        tabs: Tab.group(tabs).andand.each { |_,tabs| tabs.map!(&:to_h) },
        embedded: embedded
      }.compact
    end
  end
end
