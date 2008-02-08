require 'aquarium/utils/type_utils'

# Convert various strings, symbols, object ids, etc. into valid "names" that
# can be used as method names, etc.
module Aquarium
  module Utils
    module NameUtils

      @@char_expr_map = {
        '='  => '_equal_',
        '?'  => '_questionmark_',
        '!'  => '_exclamationmark_',
        '~'  => '_tilde_',
        '-'  => '_minus_',
        '+'  => '_plus_',
        '/'  => '_slash_',
        '*'  => '_star_',
        '<'  => '_lessthan_',
        '>'  => '_greaterthan_',
        '<<' => '_leftshift_',
        '>>' => '_rightshift_',
        '=~' => '_matches_',
        '%'  => '_percent_',
        '^'  => '_caret_',
        '[]' => '_brackets_',
        '&'  => '_ampersand_',
        '|'  => '_pipe_',
        '`'  => '_backtick_'
      }

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
        new_name = method_name.to_s
        @@char_expr_map.keys.sort{|x,y| y.length <=> x.length}.each do |expr|
          new_name.gsub! expr, @@char_expr_map[expr]
        end
        new_name.intern
      end
    end
  end
end