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
        return result
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
          result_for_expression = find_namespace_matched expr
          if result_for_expression.size > 0
            result.append_matched result_for_expression
          else
            result.append_not_matched({expression => Set.new([])})
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
        return {} if expression.nil?
        found_types = [Module]
        expr = expression.class.eql?(Regexp) ? expression.source : expression.to_s
        return {} if expr.empty?
        expr.split("::").each do |subexp|
          found_types = find_next_types found_types, subexp
          break if found_types.size == 0
        end
        make_return_hash found_types, []
      end

      def find_next_types parent_types, subname
        # grep <parent>.constants because "subname" may be a regexp string!.
        # Then use const_get to get the type itself.
        found_types = []
        parent_types.each do |parent|
          matched = parent.constants.grep(/^#{subname}$/)
          matched.each {|m| found_types << parent.const_get(m)}
        end
        found_types
      end
  
      def make_return_hash found, unmatched
        h={}
        h[:not_matched] = unmatched if unmatched.size > 0
        found.each {|x| h[x] = Set.new([])}
        h
      end
    end
  end
end
