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
      def find options = {}
        result   = Aquarium::Finders::FinderResult.new
        excluded = Aquarium::Finders::FinderResult.new
        unknown_options = []
        input_type_nil = false
        options.each do |option, value|
          unless TypeFinder.is_recognized_option option
            unknown_options << option
            next
          end
          if value.nil?
            input_type_nil = true
            next
          end
          if option.to_s =~ /^exclude_/
            excluded << find_matching(value, option)
          else
            result << find_matching(value, option)
          end
        end
        handle_errors unknown_options, input_type_nil
        result - excluded
      end
  
      protected

      def handle_errors unknown_options, input_type_nil
        message = ""
        message += "Unknown options: #{unknown_options.inspect}. " unless unknown_options.empty?
        message += "Input type specification can't be nil! " if input_type_nil
        raise Aquarium::Utils::InvalidOptions.new(message) unless message.empty?
      end

      def self.is_recognized_option option_or_symbol
        %w[name names type types].each do |t|
          ['', "exclude_"].each do |excl| 
            return true if ["#{excl}#{t}", "#{excl}#{t}_and_descendents", "#{excl}#{t}_and_ancestors"].include?(option_or_symbol.to_s)
          end
        end
        false
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

      def find_namespace_matched expression, option
        expr = expression.kind_of?(Regexp) ? expression.source : expression.to_s
        return nil if expr.empty?
        found_types = [Object]
        split_expr = expr.split("::")
        split_expr.each_with_index do |subexp, index|
          next if subexp.size == 0
          found_types = find_next_types found_types, subexp, (index == 0), (index == (split_expr.size - 1))
          break if found_types.size == 0
        end
        if found_types.size > 0
          finish_and_make_successful_result found_types, option
        else
          make_failed_result expression
        end
      end

      # For a name (not a regular expression), return the corresponding type.
      # (Adapted from the RubyQuiz #113 solution by James Edward Gray II)
      def find_by_name type_name, option
        name = type_name.to_s  # in case it's a symbol...
        return nil if name.nil? || name.strip.empty?
        name.strip!
        begin
          found = [name.split("::").inject(Object) { |parent, const| parent.const_get(const) }]
          finish_and_make_successful_result found, option
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
