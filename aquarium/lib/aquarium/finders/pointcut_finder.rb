require 'aquarium/utils'
require 'aquarium/finders/finder_result'

# Finds pointcuts by name, either class variables, class constants or both. 
module Aquarium
  module Finders
    class PointcutFinder
      include Aquarium::Utils::OptionsUtils

      POINTCUT_FINDER_CANONICAL_OPTIONS = {}
      ['', 'constants_', 'class_variables_'].each do |prefix|
        POINTCUT_FINDER_CANONICAL_OPTIONS["#{prefix}matching"] = ["#{prefix}with_names_matching", "#{prefix}named"]
      end
      
      CANONICAL_OPTIONS = Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS.merge(POINTCUT_FINDER_CANONICAL_OPTIONS)
      canonical_options_given_methods CANONICAL_OPTIONS
      canonical_option_accessor CANONICAL_OPTIONS
      
      # Usage:
      #  finder_result = PointcutFinder.new.find [:option1 => [...] ]
      # where the allowed options include all the options supported by TypeFinder for locating
      # types and one of the following options for specifying the name(s) of the pointcuts.
      #
      # <tt>:matching => a variable/constant name, regular expression, or array of the same</tt>::
      # <tt>:with_names_matching => same</tt>::
      # <tt>:named => same</tt>::
      #   The name(s) of the pointcuts to find, either constants or class variables.
      #
      def find options = {}
        init_specification options, CANONICAL_OPTIONS do 
          finish_specification_initialization
        end
        result = do_find_pointcuts unless noop
        unset_specification
        result 
      end

      class PoincutFinderResult < Aquarium::Finders::FinderResult
        def found_pointcuts
          matched.values.inject([]) {|pcs, set| pcs += set.to_a; pcs}
        end
      end
      
      protected

      POINTCUT_FINDER_CANONICAL_OPTIONS_KEYS_AS_SYMBOLS = POINTCUT_FINDER_CANONICAL_OPTIONS.keys.map {|k| k.intern}

      def finish_specification_initialization
        raise Aquarium::Utils::InvalidOptions.new("No options specified") unless any_types_given?
      end
      
      # Hack. Since the finder could be reused, unset the specification created by #find.
      def unset_specification
        @specification = {}
      end
      
      def do_find_pointcuts
        types_search_result = Aquarium::Finders::TypeFinder.new.find specification_without_pointcut_names
        return types_search_result if types_search_result.matched.empty?
        types = types_search_result.matched.keys
        pointcuts = PoincutFinderResult.new
        unless any_names_given? 
          pointcuts << find_constant_pointcuts(types)
          pointcuts << find_class_variable_pointcuts(types)
          return pointcuts
        end
        names = matching_given
        unless names.empty?
          pointcuts << find_constant_pointcuts(types, names)
          pointcuts << find_class_variable_pointcuts(types, names)
        end
        names = constants_matching_given
        unless names.empty?
          pointcuts << find_constant_pointcuts(types, names)
        end
        names = class_variables_matching_given
        unless names.empty?
          pointcuts << find_class_variable_pointcuts(types, names)
        end
        pointcuts
      end
      
      def find_constant_pointcuts types, names = :all
        pointcuts = PoincutFinderResult.new
        types.each do |t|
          candidates = t.constants.select {|c| matches_name(c, names)}
          candidates.each do |c|
            if t.const_defined? c
              con = t.const_get c
              pointcuts.append_matched({t => con}) if con.kind_of?(Aquarium::Aspects::Pointcut)
            end
          end
        end
        pointcuts
      end
      
      def find_class_variable_pointcuts types, names = :all
        pointcuts = PoincutFinderResult.new
        types.each do |t|
          candidates = t.class_variables.select {|c| matches_name(c, to_class_variable_name(names))}
          candidates.each do |c|
            con = t.send :class_variable_get, c
            pointcuts.append_matched({t => con}) if con.kind_of?(Aquarium::Aspects::Pointcut)
          end
        end
        pointcuts
      end
      
      def matches_name candidate, names
        return true if names == :all
        if names.kind_of? Regexp
          names.match candidate
        elsif names.kind_of?(String) or names.kind_of?(Symbol)
          names.to_s.eql? candidate
        else
          names.inject(false) {|matches, name| matches = true if matches_name(candidate, name); matches}
        end
      end
      
      def to_class_variable_name names
        return names if names == :all
        if names.kind_of? Regexp
          names  # no change
        elsif names.kind_of?(String) or names.kind_of?(Symbol)
          names.to_s =~ /^@@/ ? names.to_s : "@@#{names}"
        else
          names.inject([]) {|result, name| result << to_class_variable_name(name); result}
        end
      end
      
      def any_types_given?
        types_given? or types_and_descendents_given? or types_and_ancestors_given?
      end

      def any_names_given?
        matching_given? or constants_matching_given? or class_variables_matching_given?
      end

      def specification_without_pointcut_names
        @specification.reject {|key,v| POINTCUT_FINDER_CANONICAL_OPTIONS_KEYS_AS_SYMBOLS.include?(key)}
      end
    end
  end
end