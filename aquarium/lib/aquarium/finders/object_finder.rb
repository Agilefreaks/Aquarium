require 'set'
require File.dirname(__FILE__) + '/../utils/array_utils'
require File.dirname(__FILE__) + '/type_finder'


# Queries the ObjectSpace, so "immediate" objects are never returned.
# Uses Aquarium::Finders::TypeFinder to map type name regular expressions to types.

module Aquarium
  module Finders
    # Deprecated - Will be removed in a future release!
    class ObjectFinder
      include Aquarium::Utils::ArrayUtils

      # finder_result = ObjectFinder.new.find [:types => [type_names_and_regexps] | :type => type_name_or_regexp]
      # where the input types are regular expressions, there may be 0 to
      # many matching types that appear in the returned hash.
      # Use #find_all_by_types to find objects matching actual types, not just
      # names or regular expressions.
      # <tt>:types => type_names_and_regexps</tt>::
      #   One or an array of type names and regular expessions to match. 
      #
      # <tt>:type => type_name_or_regexp</tt>::
      #   A type name or regular expession to match. 
      #
      # Actually, there is effectively no difference between <tt>:types</tt> and
      # <tt>:type</tt>. The singular form is "sugar"...
      def find options = {}
        type_regexpes_or_names  = make_array options[:types]
        type_regexpes_or_names += make_array options[:type]
        if type_regexpes_or_names.empty?
          return Aquarium::Finders::FinderResult.new
        end
        self.find_all_by type_regexpes_or_names
      end
  
      # Input is a list or array object with names and/or regular expressions.  
      def find_all_by *possible_type_regexpes_or_names
        raise "Input name or name array can't be nil!" if possible_type_regexpes_or_names.nil?
        result = Aquarium::Finders::FinderResult.new
        make_array(*possible_type_regexpes_or_names).each do |expression|
          found_types = Aquarium::Finders::TypeFinder.new.find :types => expression 
          found_types.matched_keys.each do |type| 
            result << find_all_by_types(type)
          end
          found_types.not_matched_keys.each do |type| 
            result.append_not_matched({type => Set.new([])})
          end
        end
        result
      end
  
      # Return the objects in ObjectSpace for the input classes and modules.
      def find_all_by_types *types
        result = Aquarium::Finders::FinderResult.new
        make_array(*types).each do |type|
          object_space.each_object(type) do |obj|
            result.append_matched type => obj
          end
          result.append_not_matched type => [] unless result.matched[type]
        end
        result
      end
  
      def initialize object_space = ObjectSpace
        @object_space = object_space
      end
  
      protected
  
      attr_reader :object_space

    end
  end
end
