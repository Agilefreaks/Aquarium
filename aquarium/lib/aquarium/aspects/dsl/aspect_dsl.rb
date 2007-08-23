require 'aquarium/aspects/aspect'

# Convenience methods added to Object to promote an AOP DSL. If you don't want these methods added to Object, 
# then only require aspect.rb and create instances of Aspect.

module Aquarium
  module Aspects
    module DSL
      module AspectDSL
        def advise *options, &block
          o = append_implicit_self options
          Aspect.new *o, &block
        end  
      
        %w[before after after_returning after_raising around].each do |advice_kind|
          class_eval(<<-ADVICE_METHODS, __FILE__, __LINE__)
            def #{advice_kind} *options, &block
              advise :#{advice_kind}, *options, &block
            end
          ADVICE_METHODS
        end
      
        %w[after after_returning after_raising].each do |after_kind|
          class_eval(<<-AFTER, __FILE__, __LINE__)
            def before_and_#{after_kind} *options, &block
              advise(:before, :#{after_kind}, *options, &block)
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
          Pointcut.new *o, &block
        end

        private
        def append_implicit_self options
          opts = options.dup
          if (!opts.empty?) && opts.last.kind_of?(Hash)
            opts.last[:default_object] = self
          else
            opts << {:default_object => self}
          end
          opts
        end
      end
    end
  end
end

class Object
  include Aquarium::Aspects::DSL::AspectDSL
end
