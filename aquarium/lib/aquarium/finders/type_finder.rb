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
    class TypeFinder
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::TypeUtils
      include Aquarium::Utils::OptionsUtils

      def self.add_exclude_options_for option, options_hash
        all_variants = options_hash[option].dup
        options_hash["exclude_#{option}"] = all_variants.map {|x| "exclude_#{x}"}
      end
      def self.add_prepositional_option_variants_for option, options_hash
        all_variants = options_hash[option].dup + [option]
        %w[for on in within].each do |prefix|
          all_variants.each do |variant|
            options_hash[option] << "#{prefix}_#{variant}" 
          end
        end
      end
      
      TYPE_FINDER_CANONICAL_OPTIONS = {
        "types"                 => %w[type class classes module modules name names],
        "types_and_descendents" => %w[type_and_descendents class_and_descendents classes_and_descendents module_and_descendents modules_and_descendents names_and_descendents names_and_descendents],
        "types_and_ancestors"   => %w[type_and_ancestors class_and_ancestors classes_and_ancestors module_and_ancestors modules_and_ancestors name_and_ancestors names_and_ancestors],
      }
      TYPE_FINDER_CANONICAL_OPTIONS.keys.dup.each do |type_option|
        TypeFinder.add_prepositional_option_variants_for type_option, TYPE_FINDER_CANONICAL_OPTIONS
        TypeFinder.add_exclude_options_for               type_option, TYPE_FINDER_CANONICAL_OPTIONS
      end
      CANONICAL_OPTIONS = TYPE_FINDER_CANONICAL_OPTIONS.dup
      
      canonical_options_given_methods CANONICAL_OPTIONS
      canonical_option_accessor CANONICAL_OPTIONS
      
      # Usage:
      #  finder_result = TypeFinder.new.find [options => [...] ]
      # where
      # <tt>:types => types_and_type_names_and_regexps</tt>::
      # <tt>:names => types_and_type_names_and_regexps</tt>::
      # <tt>:type  => types_and_type_names_and_regexps</tt>::
      # <tt>:name  => types_and_type_names_and_regexps</tt>::
      #   A single type or array of types, specified using any combination of the type 
      #   name strings, the type "constants" and/or regular expessions. The four different
      #   flags are just "sugar" for each other. 
      #
      # <tt>:types_and_descendents => types_and_type_names_and_regexps</tt>::
      # <tt>:names_and_descendents => types_and_type_names_and_regexps</tt>::
      # <tt>:type_and_descendents  => types_and_type_names_and_regexps</tt>::
      # <tt>:name_and_descendents  => types_and_type_names_and_regexps</tt>::
      #
      # Same as for <tt>:types</tt> <i>etc.</i>, but also match their descendents.
      #
      # <tt>:types_and_ancestors => types_and_type_names_and_regexps</tt>::
      # <tt>:names_and_ancestors => types_and_type_names_and_regexps</tt>::
      # <tt>:type_and_ancestors  => types_and_type_names_and_regexps</tt>::
      # <tt>:name_and_ancestors  => types_and_type_names_and_regexps</tt>::
      #
      # Same as for <tt>:types</tt> <i>etc.</i>, but also match their ancestors.
      # This option will also match <tt>Class</tt>, <tt>Module</tt>, <i>etc.</>, 
      # so use with caution!
      #
      # To get both descendents and ancestors, use both options with the same type
      # specification.
      #
      # The "other options" include the following:
      #
      #
      # <tt>:exclude_type  => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_types => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_name  => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_names => types_and_type_names_and_regexps</tt>::
      #   Exclude the specified type or list of types from the list of matched types. 
      #   These excluded types <b>won't</b> appear in the FinderResult#not_matched. 
      #
      # <tt>:exclude_types_and_descendents => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_names_and_descendents => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_type_and_descendents  => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_name_and_descendents  => types_and_type_names_and_regexps</tt>::
      #
      # <tt>:exclude_types_and_ancestors => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_names_and_ancestors => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_type_and_ancestors  => types_and_type_names_and_regexps</tt>::
      # <tt>:exclude_name_and_ancestors  => types_and_type_names_and_regexps</tt>::
      #
      # Exclude the descendents or ancestors, as well.
      #
      # Because of the special sigificance of the module ("namespace") separator "::", the rules
      # for the regular expressions are as follows. Assume that "subexp" is a "sub regular
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
  
      
      protected

      # Hack. Since the finder could be reused, unset the specification created by #find.
      def unset_specification
        @specification = {}
      end
      
      def do_find_types
        result   = Aquarium::Finders::FinderResult.new
        excluded = Aquarium::Finders::FinderResult.new
        return result if noop
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
        result = Aquarium::Finders::FinderResult.new
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
        all = prettify(found + handle_ancestors_and_descendents(found, option))
        hash = make_return_hash(all)
        Aquarium::Finders::FinderResult.new hash
      end
      
      def make_failed_result name
        Aquarium::Finders::FinderResult.new :not_matched => {name => Set.new([])}
      end
      
      def handle_ancestors_and_descendents types, option
        result = []
        result << add_descendents(types) if should_find_descendents(option)
        result << add_ancestors(types)   if should_find_ancestors(option)
        result
      end
      
      def add_descendents types
        types.inject([]) { |memo, t| memo << Aquarium::Utils::TypeUtils.descendents(t) }
      end
      def add_ancestors types
        types.inject([]) { |memo, t| memo << t.ancestors }
      end

      def should_find_descendents option
        option.to_s.include? "_descendents"
      end
      def should_find_ancestors option
        option.to_s.include? "_ancestors"
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
