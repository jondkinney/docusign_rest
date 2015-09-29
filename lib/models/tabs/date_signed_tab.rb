module Docusign
  class DateSignedTab < Tab
    def to_h
      super.merge(value: value).compact
    end
  end
end
