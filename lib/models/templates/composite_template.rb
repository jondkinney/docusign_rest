module Docusign

  class CompositeTemplate < Template
    attr_accessor :server_templates, :inline_templates

    def initialize(server_template_ids: nil, recipients: nil)
      super()
      @server_templates = ServerTemplate.from_template_ids(server_template_ids)
      if recipients.present?
        @inline_templates = [ InlineTemplate.new(sequence: 1, recipients: recipients) ]
      end
    end

    def to_h
      {
        serverTemplates: server_templates.andand.map(&:to_h),
        inlineTemplates: inline_templates.andand.map(&:to_h),
      }.compact
    end

  end
end
