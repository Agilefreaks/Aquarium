module Aquarium
  module Utils
    # == Invalid Options
    # The exception thrown when invalid options to any API methods are detected.
    class InvalidOptions < Exception 
      def initialize *args
        super
      end
    end
  end
end
