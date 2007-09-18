require 'aquarium/utils/type_utils'

# Convert various strings, symbols, object ids, etc. into valid "names" that
# can be used as method names, etc.
module Aquarium
  module Utils
    module NameUtils

      def self.make_type_or_object_key type_or_object
        if Aquarium::Utils::TypeUtils.is_type?(type_or_object) 
          make_valid_type_name type_or_object
        else
          make_valid_object_name type_or_object
        end
      end

      def self.make_valid_type_name type
        type.name.gsub(/:/, '_')
      end

      def self.make_valid_object_name type_or_object
        "#{make_valid_type_name(type_or_object.class)}_#{make_valid_object_id_name(type_or_object.object_id)}"
      end

      # Fixes Tracker #13864.
      def self.make_valid_object_id_name object_id
        object_id.to_s.gsub(/^-/, "_neg_")
      end

      def self.make_valid_attr_name_from_method_name method_name
        method_name.to_s.gsub("=","_equalsign_").gsub("?", "_questionmark_").gsub("!", "_exclamationmark_").gsub("~", "_tilde_").intern
      end
    end
  end
end