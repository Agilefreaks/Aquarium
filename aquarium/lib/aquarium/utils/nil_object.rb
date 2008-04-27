
module Aquarium
  module Utils
    # An implementation of the Null Object Pattern (renamed "Nil" for Ruby).
    # All methods not defined by Object simply return the Aquarium::Utils::NilObject itself.
    # Users can subclass or add methods to instances to customize the behavior.
    class Aquarium::Utils::NilObject
        
      def eql? other
        other.kind_of? NilObject
      end
            
      def method_missing method_sym, *args
        self
      end
    end
  end
end