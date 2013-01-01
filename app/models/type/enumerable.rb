module Type::Enumerable
  extend ActiveSupport::Concern

  module ClassMethods
    def values
      @values || {}
    end

    def value(name, value)
      @values = {} unless @values

      unless @values[name]
        @values[name] = self.find_or_create_by_value(value)
        @values[name].save!
      end
      
      define_singleton_method name do
        @values[name]
      end      
    end
  end
  
  module InstanceMethods
    def name
      self.class.values.invert[self]
    end
  end
end
