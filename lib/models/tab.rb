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

    def self.collection_name
      raise "implement collection_type in subclass!"
    end

    def self.class_for(key)
      @@tab_types ||= subclasses.reduce({}) do |result, tab_subclass|
        result[tab_subclass.collection_name] = tab_subclass
        result
      end
      @@tab_types[key.to_sym]
    end

  end
end
