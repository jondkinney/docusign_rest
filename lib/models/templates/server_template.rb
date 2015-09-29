module Docusign

  class ServerTemplate < Template
    attr_accessor :template_id

    def initialize(sequence: nil, template_id: nil)
      super(sequence: sequence)
      @template_id = template_id
    end

    def to_h
      super.merge(templateId: template_id)
    end

    def self.from_template_ids(template_ids)
      return  unless template_ids.present?
      template_ids.andand.map.with_index(1) do |template_id, sequence|
        ServerTemplate.new(sequence: sequence, template_id: template_id)
      end
    end

  end

end
