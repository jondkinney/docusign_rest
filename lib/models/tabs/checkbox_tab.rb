module Docusign
  class CheckboxTab < Tab
    def to_h
      super.merge(selected: value)
    end
  end
end
