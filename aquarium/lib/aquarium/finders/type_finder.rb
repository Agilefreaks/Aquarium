require 'set'
require File.dirname(__FILE__) + '/../utils/array_utils'
require File.dirname(__FILE__) + '/../utils/invalid_options'
require File.dirname(__FILE__) + '/../extensions/regexp'
require File.dirname(__FILE__) + '/../extensions/symbol'
require File.dirname(__FILE__) + '/finder_result'

# Finds types known to the runtime environment.
module Aquarium
  module Finders
    class TypeFinder
      include Aquarium::Utils::ArrayUtils

      # Usage:
      #  finder_result = TypeFinder.new.find [ :types => ... | :names => ... ], [ :options => [...] ]
      # where
      # <tt>:types => types_and_type_names_and_regexps</tt>::
      #   The types or type names/regular expessions to match. 
      #   Specify one or an array of values.
      #
      # <tt>:names => types_and_type_names_and_regexps</tt>::
      #   A synonym for <tt>:types</tt>. (Sugar)
      #
      # <tt>:type => type_or_type_name_or_regexp</tt>::
      #   Sugar for specifying one type
      #
      # <tt>:name => type_or_type_name_or_regexp</tt>::
      #   Sugar for specifying one type name.
      #
      # Actually, there is actually no difference between <tt>:types</tt>, 
      # <tt>:type</tt>, <tt>:names</tt>, and <tt>:name</tt>. The extra forms are "sugar"...
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
      def find options = {}
        result = Aquarium::Finders::FinderResult.new
        unknown_options = []
        options.each do |option, value|
          case option.to_s
          when "names", "types", "name", "type" 
            result << find_all_by(value)
          else
            unknown_options << option
          end
        end
        raise Aquarium::Utils::InvalidOptions.new("Unknown options: #{unknown_options.inspect}.") if unknown_options.size > 0
        result
      end
  
      # For a name (not a regular expression), return the corresponding type.
      # (Adapted from the RubyQuiz #113 solution by James Edward Gray II)
      def find_by_name type_name
        name = type_name.to_s  # in case it's a symbol...
        return nil if name.nil? || name.strip.empty?
        name.strip!
        found = []
        begin
          found << name.split("::").inject(Object) { |parent, const| parent.const_get(const) }
          Aquarium::Finders::FinderResult.new(make_return_hash(found, []))
        rescue NameError => ne
          Aquarium::Finders::FinderResult.new(make_return_hash([], [type_name]))
        end
      end
      
      alias :find_by_type :find_by_name
  
      def find_all_by regexpes_or_names
        raise Aquarium::Utils::InvalidOptions.new("Input type(s) can't be nil!") if regexpes_or_names.nil?
        result = Aquarium::Finders::FinderResult.new
        expressions = make_array regexpes_or_names
        expressions.each do |expression|
          expr = strip expression
          next if empty expr
          if expr.kind_of? Regexp
            result << find_namespace_matched(expr)
          else
            result << find_by_name(expr)
          end
        end
        result
      end

      def self.is_recognized_option option_or_symbol
        %w[name names type types].include? option_or_symbol.to_s
      end
  
      private
  
      def strip expression
        return nil if expression.nil? 
        expression.respond_to?(:strip) ? expression.strip : expression
      end
  
      def empty expression
        expression.nil? || (expression.respond_to?(:empty?) && expression.empty?)
      end
  
      def find_namespace_matched expression
        expr = expression.kind_of?(Regexp) ? expression.source : expression.to_s
        return nil if expr.empty?
        found_types = [Module]
        split_expr = expr.split("::")
        split_expr.each_with_index do |subexp, index|
          next if subexp.size == 0
          found_types = find_next_types found_types, subexp, (index == 0), (index == (split_expr.size - 1))
          break if found_types.size == 0
        end
        if found_types.size > 0
          Aquarium::Finders::FinderResult.new make_return_hash(found_types, [])
        else
          Aquarium::Finders::FinderResult.new :not_matched => {expression => Set.new([])}
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
          parent.constants.grep(regexp).each do |m| 
            found_types << get_type_from_parent(parent, m, regexp)
          end
        end
        found_types
      end
  
      def make_return_hash found, unmatched
        h={}
        h[:not_matched] = unmatched if unmatched.size > 0
        found.each {|x| h[x] = Set.new([])}
        h
      end

      protected
      def get_type_from_parent parent, name, regexp
        begin
          parent.const_get(name)
        rescue => e
          msg  = "ERROR: for enclosing type '#{parent.inspect}', #{parent.inspect}.constants.grep(/#{regexp.source}/) returned a list including #{name.inspect}."
          msg += "However, #{parent.inspect}.const_get('#{name}') raised exception #{e}. Please report this bug to the Aquarium team. Thanks."
          raise e.exception(msg)
        end
      end
    end
  end
end
