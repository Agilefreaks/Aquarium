# Adding useful methods to Symbol.
module Aquarium
  module Extensions
    module SymbolHelper
      def empty?
        return to_s.strip.empty?
      end
  
      def strip
        return to_s.strip.to_sym
      end
  
      def <=> other_symbol
        self.to_s <=> other_symbol.to_s
      end
    end
  end
end

class Symbol
  include Aquarium::Extensions::SymbolHelper
end