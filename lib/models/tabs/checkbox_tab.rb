module Docusign
  class CheckboxTab < Tab
    def to_h
      super.merge(selected: value)
    end

    def self.collection_name
      :checkboxTabs
    end

  end
end
