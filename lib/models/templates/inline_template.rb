module Docusign
  class InlineTemplate < Template

    attr_accessor :recipients

    def initialize(sequence: nil, recipients: nil)
      super(sequence: sequence)
      @recipients = recipients
    end

    def to_h
      return super  unless recipients.present?
      super.merge(
        recipients: {
          signers: recipients.map(&:to_h)
        }
      ).compact
    end
  end
end
