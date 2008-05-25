require 'set'
require File.dirname(__FILE__) + '/../utils/array_utils'
require File.dirname(__FILE__) + '/../utils/type_utils'
require File.dirname(__FILE__) + '/../utils/invalid_options'
require File.dirname(__FILE__) + '/../extensions/hash'
require File.dirname(__FILE__) + '/../extensions/regexp'
require File.dirname(__FILE__) + '/../extensions/symbol'
require File.dirname(__FILE__) + '/finder_result'

# Finds types known to the runtime environment.
module Aquarium
  module Finders
    # == TypeFinder
    # Locate types.
    class TypeFinder
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::TypeUtils
      include Aquarium::Utils::OptionsUtils

      class TypeFinderResult < Aquarium::Finders::FinderResult
        include Enumerable
        def each
          matched_keys.each { |x| yield x }
        end
      end
      
      def self.add_ancestors_descendents_and_nested_option_variants_for option, options_hash
        all_variants = options_hash[option].dup
        options_hash["#{option}_and_descendents"] = all_variants.map {|x| "#{x}_and_descendents"}
        options_hash["#{option}_and_ancestors"]   = all_variants.map {|x| "#{x}_and_ancestors"}
        options_hash["#{option}_and_nested_types"] = 
          all_variants.map {|x| "#{x}_and_nested_types"} + all_variants.map {|x| "#{x}_and_nested"}
      end
      
      TYPE_FINDER_CANONICAL_OPTIONS = {
        "types" => %w[type class classes module modules name names],
      }
      # Add the ancestors, descendents, and nested variants first, then add all the preposition and 
      # exclude variants, so the latter are added to the former...
      TYPE_FINDER_CANONICAL_OPTIONS.keys.dup.each do |type_option|
        add_ancestors_descendents_and_nested_option_variants_for type_option, TYPE_FINDER_CANONICAL_OPTIONS
      end
      TYPE_FINDER_CANONICAL_OPTIONS.keys.dup.each do |type_option|
        add_prepositional_option_variants_for type_option, TYPE_FINDER_CANONICAL_OPTIONS
        add_exclude_options_for               type_option, TYPE_FINDER_CANONICAL_OPTIONS
      end
      
      CANONICAL_OPTIONS = TYPE_FINDER_CANONICAL_OPTIONS.dup
      
      canonical_options_given_methods CANONICAL_OPTIONS
      canonical_option_accessor CANONICAL_OPTIONS
      
      # Returns a TypeFinder::TypeFinderResult, where the "matched" keys are the input 
      # types, type names, and/or regular expressions, and objects for which matches were found and the 
      # corresponding values are the class constant or variable pointcuts that were found.
      # The keys in the "not_matched" part of the result are the specified types and objects
      # for which no matches were found.
      #
      # The options are as follows:
      #
      # ==== Types
      # A single type, type name, name regular expression, or an array of the same. (Mixed allowed.)
      # * <tt>:types => types_and_type_names_and_regexps</tt>
      # * <tt>:names => types_and_type_names_and_regexps</tt>
      # * <tt>:type  => types_and_type_names_and_regexps</tt>
      # * <tt>:name  => types_and_type_names_and_regexps</tt>
      #
      # ==== Types and Descendents
      # A single type, type name, name regular expression, or an array of the same. (Mixed allowed.)
      # Matching types and their descendents will be found. A type that includes a module is considered
      # a descendent, since the module would show up in that type's ancestors.
      # * <tt>:types_and_descendents => types_and_type_names_and_regexps</tt>
      # * <tt>:names_and_descendents => types_and_type_names_and_regexps</tt>
      # * <tt>:type_and_descendents  => types_and_type_names_and_regexps</tt>
      # * <tt>:name_and_descendents  => types_and_type_names_and_regexps</tt>
      #
      # ==== Types and Ancestors
      # A single type, type name, name regular expression, or an array of the same. (Mixed allowed.)
      # Matching types and their ancestors will be found.
      # * <tt>:types_and_ancestors => types_and_type_names_and_regexps</tt>
      # * <tt>:names_and_ancestors => types_and_type_names_and_regexps</tt>
      # * <tt>:type_and_ancestors  => types_and_type_names_and_regexps</tt>
      # * <tt>:name_and_ancestors  => types_and_type_names_and_regexps</tt>
      #
      # ==== Types and Nested Types
      # A single type, type name, name regular expression, or an array of the same. (Mixed allowed.)
      # Matching types and any types nested within them will be found.
      # * <tt>:types_and_nested_types => types_and_type_names_and_regexps</tt>
      # * <tt>:names_and_nested_types => types_and_type_names_and_regexps</tt>
      # * <tt>:type_and_nested_types  => types_and_type_names_and_regexps</tt>
      # * <tt>:name_and_nested_types  => types_and_type_names_and_regexps</tt>
      # * <tt>:types_and_nested => types_and_type_names_and_regexps</tt>
      # * <tt>:names_and_nested => types_and_type_names_and_regexps</tt>
      # * <tt>:type_and_nested  => types_and_type_names_and_regexps</tt>
      # * <tt>:name_and_nested  => types_and_type_names_and_regexps</tt>
      #
      # Note: This option will also match <tt>Class</tt>, <tt>Module</tt>, <i>etc.</>, 
      # so use with caution!
      #
      # To get both descendents and ancestors, use both options with the same type
      # specification.
      #
      # ==== Exclude Types
      # Exclude the specified type(s) from the list of matched types. 
      # Note: These excluded types <i>won't</i> appear in the FinderResult#not_matched. 
      # * <tt>:exclude_type  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_types => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_name  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_names => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_types_and_descendents => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_names_and_descendents => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_type_and_descendents  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_name_and_descendents  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_types_and_ancestors => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_names_and_ancestors => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_type_and_ancestors  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_name_and_ancestors  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_types_and_nested_types => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_names_and_nested_types => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_type_and_nested_types  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_name_and_nested_types  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_types_and_nested => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_names_and_nested => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_type_and_nested  => types_and_type_names_and_regexps</tt>
      # * <tt>:exclude_name_and_nested  => types_and_type_names_and_regexps</tt>
      #
      # ==== Namespaces (Modules) and Regular Expressions
      # Because of the special sigificance of the module ("namespace") separator "::", 
      # special rules for the regular expressions apply. Normally, you can just use the
      # "*_and_nested_types" or "*_and_nested" to match enclosed types, but if you want to
      # be selective, note the following. First, assume that "subexp" is a "sub regular 
      # expression" that results if you split on the separator "::".
      #
      # A full regexp with no "::"::
      #   Allow partial matches, <i>i.e.</i>, as if you wrote <tt>/^.*#{regexp}.*$/.</tt>
      # 
      # A subexp before the first "::"::
      #   It behaves as <tt>/^.*#{subexp}::.../</tt>, meaning that the end of "subexp" 
      #   must be followed by "::".
      #
      # A subexp after the last "::"::
      #   It behaves as <tt>/...::#{subexp}$/</tt>, meaning that the beginning of "subexp"
      #   must immediately follow a "::".
      #
      # For a subexp between two "::"::
      #   It behaves as <tt>/...::#{subexp}::.../</tt>, meaning that the subexp must match 
      #   the whole name between the "::" exactly.
      #
      # Note: a common idiom in aspects is to include descendents of a type, but not the type
      # itself. You can do as in the following example:
      #   <tt>... :type_and_descendents => "Foo", :exclude_type => "Foo" 
      # 
      def find options = {}
        init_specification options, CANONICAL_OPTIONS
        result = do_find_types
        unset_specification
        result 
      end
  
      private

      # Hack. Since the finder could be reused, unset the specification created by #find.
      def unset_specification
        @specification = {}
      end
      
      def do_find_types
        result = TypeFinderResult.new
        return result if noop
        excluded = TypeFinderResult.new
        @specification.each do |option, types|
          next unless TYPE_FINDER_CANONICAL_OPTIONS.keys.include?(option.to_s)
          next if types.nil? or types.empty?
          target_result = option.to_s =~ /^exclude_/ ? excluded : result
          types.each do |value|
            target_result << find_matching(value, option)
          end
        end
        result - excluded
      end
      
      def find_matching regexpes_or_names, option
        result = TypeFinderResult.new
        expressions = make_array regexpes_or_names
        expressions.each do |expression|
          expr = strip expression
          next if empty expr
          if expr.kind_of? Regexp
            result << find_namespace_matched(expr, option)
          else
            result << find_by_name(expr, option)
          end
        end
        result
      end

      def find_namespace_matched regexp, option
        expr = regexp.source
        return nil if expr.empty?
        found_types = [Object]
        split_expr = expr.split("::")
        split_expr.each_with_index do |subexp, index|
          next if subexp.size == 0
          found_types = find_next_types found_types, subexp, (index == 0), (index == (split_expr.size - 1))
          break if found_types.size == 0
        end
        # JRuby returns types that aren't actually defined by the enclosing namespace.
        # As a sanity check, reject types whose names don't match the full regexp.
        found_types.reject! {|t| t.name !~ regexp}
        if found_types.size > 0
          finish_and_make_successful_result found_types, option
        else
          make_failed_result regexp
        end
      end

      # For a name (not a regular expression), return the corresponding type.
      # (Adapted from the RubyQuiz #113 solution by James Edward Gray II)
      # See also this blog: http://blog.sidu.in/2008/02/loading-classes-from-strings-in-ruby.html
      # I discovered that eval works fine with JRuby wrapper classes, while splitting on '::' and 
      # calling const_get on each module fails!
      def find_by_name type_name, option
        begin
          found = eval type_name.to_s, binding, __FILE__, __LINE__
          finish_and_make_successful_result [found], option
        rescue NameError 
          make_failed_result type_name
        end
      end
      
      def find_next_types enclosing_types, subexp, suppress_lh_ctrl_a, suppress_rh_ctrl_z
        # grep <parent>.constants because "subexp" may be a regexp string!.
        # Then use const_get to get the type itself.
        found_types = []
        lhs = suppress_lh_ctrl_a ? "" : "\\A"
        rhs = suppress_rh_ctrl_z ? "" : "\\Z"
        regexp = /#{lhs}#{subexp}#{rhs}/
        enclosing_types.each do |parent|
          next unless parent.respond_to?(:constants)
          parent.constants.grep(regexp) do |name| 
            found_types << parent.const_get(name)
          end
        end
        found_types
      end
  
      def finish_and_make_successful_result found, option
        all = prettify(found + handle_ancestors_descendents_and_nested(found, option))
        hash = make_return_hash(all)
        TypeFinderResult.new hash
      end
      
      def make_failed_result name
        TypeFinderResult.new :not_matched => {name => Set.new([])}
      end
      
      def handle_ancestors_descendents_and_nested types, option
        result = []
        result << add_ancestors(types)   if should_find_ancestors(option)
        result << add_descendents(types) if should_find_descendents(option)
        result << add_nested(types)      if should_find_nested(option)
        result
      end
      
      def add_ancestors types
        types.inject([]) { |memo, t| memo << t.ancestors }
      end
      def add_descendents types
        types.inject([]) { |memo, t| memo << Aquarium::Utils::TypeUtils.descendents(t) }
      end
      def add_nested types
        types.inject([]) { |memo, t| memo << Aquarium::Utils::TypeUtils.nested(t) }
      end

      def should_find_ancestors option
        option.to_s.include? "_ancestors"
      end
      def should_find_descendents option
        option.to_s.include? "_descendents"
      end
      def should_find_nested option
        option.to_s.include? "_nested"
      end
      
  
      def make_return_hash found
        prettify(found).inject({}) {|hash, x| hash[x] = Set.new([]); hash}
      end
      
      def prettify array
        array.flatten.uniq.inject([]) {|memo, x| memo << x unless empty(x); memo}
      end
      
      def strip expression
        return nil if expression.nil? 
        expression.respond_to?(:strip) ? expression.strip : expression
      end
  
      def empty thing
        thing.nil? || (thing.respond_to?(:empty?) && thing.empty?)
      end
  
    end
  end
end
