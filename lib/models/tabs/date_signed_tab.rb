module Docusign
  class DateSignedTab < Tab
    def to_h
      super.merge(value: value)
    end
  end
end
