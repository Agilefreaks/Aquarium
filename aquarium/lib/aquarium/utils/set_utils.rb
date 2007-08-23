require 'set'

module Aquarium
  module Utils
    module SetUtils

      # Return a set containing the input item or list of items. If the input
      # is a set or an array, it is returned. In all cases, the constructed set is a
      # flattened version of the input and any nil elements are removed by #strip_nils.
      # Note that this behavior effectively converts +nil+ to +[]+.
      def make_set *value_or_set_or_array
        strip_nils(convert_to_set(*value_or_set_or_array))
      end

      # Return a new set that is a copy of the input set with all nils removed.
      def strip_nils set
        set.delete_if {|x| x.nil?}
      end
  
      protected
      def convert_to_set *value_or_set_or_array
        if value_or_set_or_array.nil? or value_or_set_or_array.empty?
          Set.new
        elsif value_or_set_or_array[0].kind_of?(Set)
          value_or_set_or_array[0]
        else
          Set.new value_or_set_or_array.flatten
        end
      end
    end
  end
end
