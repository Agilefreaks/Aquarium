require 'aquarium/aspects/aspect'
require 'aquarium/utils/type_utils'

# Convenience methods added to the current type to provide a low-level AOP DSL. 
# If you don't want these methods added to a type, then only require aspect.rb
# and create instances of Aspect.

module Aquarium
  module DSL
        
    def advise *options, &block
      o = append_implicit_self options
      Aquarium::Aspects::Aspect.new *o, &block
    end  
  
    %w[before after after_returning after_raising around].each do |advice_kind|
      module_eval(<<-ADVICE_METHODS, __FILE__, __LINE__)
        def #{advice_kind} *options, &block
          advise :#{advice_kind}, *options, &block
        end
      ADVICE_METHODS
    end
  
    %w[after after_returning after_raising].each do |after_kind|
      module_eval(<<-AFTER, __FILE__, __LINE__)
        def before_and_#{after_kind} *options, &block
          advise :before, :#{after_kind}, *options, &block
        end
      AFTER
    end
    
    alias :after_returning_from :after_returning
    alias :after_raising_within :after_raising
    alias :after_raising_within_or_returning_from :after
  
    alias :before_and_after_returning_from :before_and_after_returning
    alias :before_and_after_raising_within :before_and_after_raising
    alias :before_and_after_raising_within_or_returning_from :before_and_after
 
    def pointcut *options, &block
      o = append_implicit_self options
      Aquarium::Aspects::Pointcut.new *o, &block
    end

    # Add the methods as class, not instance, methods.
    def self.append_features clazz
      super(class << clazz; self; end)
    end
    
    private
    def append_implicit_self options
      opts = options.dup
      if (!opts.empty?) && opts.last.kind_of?(Hash)
        opts.last[:default_objects] = self
      else
        opts << {:default_objects => self}
      end
      opts
    end
  end
end

# Backwards compatibility with old name.
module Aquarium
  module Aspects
    module DSL
      module AspectDSL
        include Aquarium::DSL
      end
    end
  end
end
