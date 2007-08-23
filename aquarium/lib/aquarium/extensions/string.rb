module Aquarium
  module Extensions
    module StringHelper
      def to_camel_case
        split('_').map {|s| s[0,1]=s[0,1].capitalize; s}.join
      end
    end
  end
end

class String
  include Aquarium::Extensions::StringHelper
end