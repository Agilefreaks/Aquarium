# Adding useful methods to Regexp.
module Aquarium
  module Extensions
    module RegexpHelper
      def empty?
        source.strip.empty?
      end
      def strip
        Regexp.new(source.strip)
      end
      def <=> other
        to_s <=> other.to_s
      end
    end
  end
end

class Regexp
  include Aquarium::Extensions::RegexpHelper
end