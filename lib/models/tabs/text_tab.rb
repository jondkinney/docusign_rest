module Docusign
  class TextTab < Tab
    def initialize(options={})
      super
    end

    def to_h
      super.merge(value: value)
    end

    def self.collection_name
      :textTabs
    end

  end
end
