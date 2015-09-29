module Docusign
  class Tab
    attr_accessor :id, :label, :value, :dirty

    def initialize(label: nil, value: nil, id: nil)
      @id = id
      @label = label
      @value = value
    end

    def to_h
      {
        tabId: id,
        tabLabel: label,
        locked: true
      }.compact
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

    def self.group(tabs)
      return  unless tabs.present?
      tabs.
        select { |e| e.is_a?(Tab) }.
        reject { |e| e.class == Tab }.
        compact.
        group_by { |tab| tab.collection_name }
    end


  end
end
