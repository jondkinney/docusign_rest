module Docusign
  class TextTab < Tab
    def to_h
      super.merge(value: (value.nil? ? '' : value).to_s).compact
    end
  end
end
