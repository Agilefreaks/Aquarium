require 'aquarium/utils/array_utils'

module Aquarium
  module Utils
    module HashUtils
      include Aquarium::Utils::ArrayUtils

      # Convert the input item or array into a hash with a nil value or the result
      # of evaluating the optional input block, which takes a single argument for the item.
      # If the input is already a hash, it is returned unmodified.
      def make_hash item_or_array_or_hash
        return {} if item_or_array_or_hash.nil? 
        return strip_nil_keys(item_or_array_or_hash) if item_or_array_or_hash.kind_of?(Hash)
        hash = {}
        [item_or_array_or_hash].flatten.each do |element| 
          unless element.nil?
            hash[element] = block_given? ? yield(element) : nil
          end
        end
        hash
      end
  
      def strip_nil_keys hash
        hash.reject {|k,v| k.nil?}
      end
    end
  end
end
