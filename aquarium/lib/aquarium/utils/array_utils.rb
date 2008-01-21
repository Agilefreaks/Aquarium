require 'aquarium/extensions/symbol'
require 'aquarium/utils/html_escaper'

module Aquarium
  module Utils
    module ArrayUtils
  
      # Return an array containing the input item or list of items. If the input
      # is an array, it is returned. In all cases, the constructed array is a
      # flattened version of the input and any nil elements are removed by #strip_nils.
      # Note that this behavior effectively converts +nil+ to +[]+.
      def make_array *value_or_enum
        ArrayUtils.make_array value_or_enum
      end

      def self.make_array *value_or_enum
        strip_nils do_make_array(value_or_enum)
      end
      
      # Return a copy of the input array with all nils removed.
      def strip_nils array
        ArrayUtils.strip_nils array
      end
  
      def self.strip_nils array
        array.to_a.compact
      end
  
      private
      def self.do_make_array value_or_enum
        v = value_or_enum.flatten 
        v = v[0].to_a if (v.empty? == false && v[0].kind_of?(Set))
        v
      end
    end
  end
end