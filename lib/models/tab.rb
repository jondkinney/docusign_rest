module Docusign
  class Tab
    attr_accessor :id, :label, :value, :dirty

    def initialize(options={})
      @id = options[:id]
      @label = options[:label]
    end

    def to_h
      { tabId: id, tabLabel: label, locked: true }
    end

    def value=(value)
      @value = value
      @dirty = true
    end

    def dirty?
      !!dirty
    end

    def collection_name
      self.class.name.demodulize.pluralize.camelize(:lower).to_sym
    end

  end
end
