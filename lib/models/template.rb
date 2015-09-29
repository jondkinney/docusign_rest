module Docusign
  class Template
    attr_accessor :sequence

    def initialize(sequence: nil)
      @sequence = sequence
    end

    def to_h
      {
        sequence: sequence.andand.to_s
      }.compact
    end

  end
end
