require 'set'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/exclusion_handler'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/finders/finder_result'
require 'aquarium/finders/type_finder'
require 'aquarium/finders/method_finder'
require 'aquarium/aspects/default_object_handler'

module Aquarium
  module Aspects
    # == Pointcut
    # Pointcuts are queries on JoinPoints combined with binding of context data to
    # that will be useful during advice execution. The Pointcut locates the join points
    # that match the input criteria, remembering the found join points as well as the
    # the criteria that yielded no matches (mostly useful for debugging Pointcut definitions)
    class Pointcut
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::HashUtils
      include Aquarium::Utils::SetUtils
      include ExclusionHandler
      include DefaultObjectHandler

      attr_reader :specification

      # Construct a Pointcut for methods in types or objects.
      #   Pointcut.new :type{s} => [...] | :object{s} => [...] \
      #      {, :method{s} => [], :method_options => [...], \
      #      :attribute{s} => [...], :attribute_options[...]}
      # where
      # the "{}" indicate optional elements. For example, you can use
      # :types or :type.
      #
      # <tt>:types => type || [type_list]</tt>::
      # <tt>:type  => type || [type_list]</tt>::
      #   One or an array of types, type names and/or type regular expessions to match. 
      #
      # <tt>:types_and_descendents => type || [type_list]</tt>::
      # <tt>:type_and_descendents  => type || [type_list]</tt>::
      # <tt>:types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:type_and_ancestors    => type || [type_list]</tt>::
      #   One or an array of types and either their descendents or ancestors. 
      #   If you want both the descendents _and_ ancestors, use both options.
      #
      # <tt>:objects => object || [object_list]</tt>::
      # <tt>:object  => object || [object_list]</tt>::
      #   Objects to match.
      #    
      # <tt>:default_object => object</tt>::
      #   An "internal" flag used by AspectDSL#pointcut when no object or type is specified, 
      #   the value of :default_object will be used, if defined. AspectDSL#pointcut sets the 
      #   value to self, so that the user doesn't have to in the appropriate contexts.
      #   This flag is subject to change, so don't use it explicitly!
      #
      # <tt>:methods => method || [method_list]</tt>::
      # <tt>:method  => method || [method_list]</tt>::
      #   One or an array of methods, method names and/or method regular expessions to match. 
      #   By default, unless :attributes are specified, searches for public instance methods
      #   with the method option :exclude_ancestor_methods implied, unless explicit method 
      #   options are given.
      #
      # <tt>:method_options => [options]</tt>::
      #   One or more options supported by Aquarium::Finders::MethodFinder. The :exclude_ancestor_methods
      #   option is most useful.
      #
      # <tt>:attributes => attribute || [attribute_list]</tt>::
      # <tt>:attribute  => attribute || [attribute_list]</tt>::
      #   One or an array of attribute names and/or regular expessions to match. 
      #   This is syntactic sugar for the corresponding attribute readers and/or writers
      #   methods, as specified using the <tt>:attrbute_options</tt>. Any matches will be
      #   joined with the matched :methods.</tt>.
      #
      # <tt>:attribute_options => [options]</tt>::
      #   One or more of <tt>:readers</tt>, <tt>:reader</tt> (synonymous), 
      #   <tt>:writers</tt>, and/or <tt>:writer</tt> (synonymous). By default, both
      #   readers and writers are matched.
      #
      # <tt>:exclude_pointcuts   => pc || [pc_list]</tt>::
      # <tt>:exclude_pointcut    => pc || [pc_list]</tt>::
      # <tt>:exclude_join_points => jp || [jp_list]</tt>::
      # <tt>:exclude_join_point  => jp || [jp_list]</tt>::
      # <tt>:exclude_types       => type || [type_list]</tt>::
      # <tt>:exclude_types       => type || [type_list]</tt>::
      # <tt>:exclude_type        => type || [type_list]</tt>::
      # <tt>:exclude_objects     => object || [object_list]</tt>::
      # <tt>:exclude_object      => object || [object_list]</tt>::
      # <tt>:exclude_methods     => method || [method_list]</tt>::
      # <tt>:exclude_method      => method || [method_list]</tt>::
      # <tt>:exclude_attributes  => attribute || [attribute_list]</tt>::
      # <tt>:exclude_attribute   => attribute || [attribute_list]</tt>::
      #   Exclude the specified "things" from the matched join points. If pointcuts are
      #   excluded, they should be subsets of the matched pointcuts. Otherwise, the
      #   resulting pointcut will be empty!
      #
      # <tt>:exclude_types_and_descendents => type || [type_list]</tt>::
      # <tt>:exclude_type_and_descendents  => type || [type_list]</tt>::
      # <tt>:exclude_types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:exclude_type_and_ancestors    => type || [type_list]</tt>::
      #   Exclude the specified types and their descendents, ancestors.
      #   If you want to exclude both the descendents _and_ ancestors, use both options.
      #
      def initialize options = {} 
        init_specification options
        init_candidate_types 
        init_candidate_objects
        init_candidate_join_points
        init_join_points
      end
  
      attr_reader :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_types_excluded, :candidate_objects, :candidate_join_points
  
      # Two Considered equivalent only if the same join points matched and not_matched sets are equal, 
      # the specifications are equal, and the candidate types and candidate objects are equal.
      # if you care only about the matched join points, then just compare #join_points_matched
      def eql? other
        object_id == other.object_id ||
        (specification == other.specification && 
         candidate_types == other.candidate_types && 
         candidate_types_excluded == other.candidate_types_excluded && 
         candidate_objects == other.candidate_objects && 
         join_points_matched == other.join_points_matched &&
         join_points_not_matched == other.join_points_not_matched) 
      end
  
      alias :== :eql?
  
      def empty?
        return join_points_matched.empty? && join_points_not_matched.empty?
      end
  
      def inspect
        "Pointcut: {specification: #{specification.inspect}, candidate_types: #{candidate_types.inspect}, candidate_types_excluded: #{candidate_types_excluded.inspect}, candidate_objects: #{candidate_objects.inspect}, join_points_matched: #{join_points_matched.inspect}, join_points_not_matched: #{join_points_not_matched.inspect}}"
      end
  
      alias to_s inspect

      def self.make_attribute_method_names attribute_name_regexps_or_names, attribute_options = []
        readers = make_attribute_readers attribute_name_regexps_or_names
        return readers if read_only attribute_options 

        writers = make_attribute_writers readers
        return writers if write_only attribute_options
        return readers + writers
      end
  
      protected
  
      attr_writer :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_types_excluded, :candidate_objects, :candidate_join_points

      ALLOWED_OPTIONS_SINGULAR = %w[
        type object join_point method 
        exclude_type exclude_object exclude_join_point exclude_pointcut exclude_method
        default_object attribute method_option attribute_option]
      
      OTHER_ALLOWED_OPTIONS = %w[
        type_and_descendents types_and_descendents type_and_ancestors types_and_ancestors
        exclude_type_and_descendents exclude_types_and_descendents exclude_type_and_ancestors exclude_types_and_ancestors]

      OTHER_ALLOWED_SPEC_KEYS = {
        "types_and_descendents" => "type_and_descendents",
        "types_and_ancestors" => "type_and_ancestors",
        "exclude_types_and_descendents" => "exclude_type_and_descendents",
        "exclude_types_and_ancestors" => "exclude_type_and_ancestors" }

      def init_specification options
        @specification = {}
        options ||= {} 
        validate_options options
        ALLOWED_OPTIONS_SINGULAR.each do |option|
          self.instance_eval(<<-EOF, __FILE__, __LINE__)
            @specification[:#{option}s]= Set.new(make_array(options[:#{option}], options[:#{option}s]))
          EOF
        end
        OTHER_ALLOWED_SPEC_KEYS.keys.each do |option|
          self.instance_eval(<<-EOF, __FILE__, __LINE__)
            @specification[:#{option}]= Set.new(make_array(options[:#{option}], options[:#{OTHER_ALLOWED_SPEC_KEYS[option]}]))
          EOF
        end
        
        use_default_object_if_defined unless (types_given? || objects_given?)

        raise Aquarium::Utils::InvalidOptions.new(":all is not yet supported for :attributes.") if @specification[:attributes] == Set.new([:all])
        init_methods_specification options
      end
  
      def init_methods_specification options
        @specification[:methods] = Set.new(make_array(options[:methods], options[:method]))
        @specification[:methods].add(:all) if @specification[:methods].empty? and @specification[:attributes].empty?
      end
      
      def validate_options options
        knowns = []
        ALLOWED_OPTIONS_SINGULAR.each do |x| 
          knowns << x.intern
          knowns << "#{x}s".intern
        end
        OTHER_ALLOWED_OPTIONS.each do |x| 
          knowns << x.intern
        end
        unknowns = options.keys - knowns
        raise Aquarium::Utils::InvalidOptions.new("Unknown options specified: #{unknowns.inspect}") if unknowns.size > 0
      end
  
      def self.read_only attribute_options
        read_option(attribute_options) && !write_option(attribute_options)
      end
  
      def self.write_only attribute_options
        write_option(attribute_options) && !read_option(attribute_options)
      end
  
      def self.read_option attribute_options
        attribute_options.include?(:readers)  || attribute_options.include?(:reader)
      end
  
      def self.write_option attribute_options
        attribute_options.include?(:writers)  || attribute_options.include?(:writer)
      end
  
      %w[types objects join_points methods attributes method_options attribute_options].each do |name|
        class_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}_given
            @specification[:#{name}]
          end
  
          def #{name}_given?
            not (#{name}_given.nil? or #{name}_given.empty?)
          end
        EOF
      end

      %w[types objects join_points pointcuts methods].each do |name|
        class_eval(<<-EOF, __FILE__, __LINE__)
          def exclude_#{name}_given
            @specification[:exclude_#{name}]
          end
  
          def exclude_#{name}_given?
            not (exclude_#{name}_given.nil? or exclude_#{name}_given.empty?)
          end
        EOF
      end

      private 
  
      def init_candidate_types 
        finder_options = {}
        exclude_finder_options = {}
        ['', 'exclude_'].each do |prefix|
          ['', '_and_ancestors', '_and_descendents'].each do |suffix|
            # Because the user might be asking for descendents and/or ancestors, we convert explicitly-specified
            # types into names, then "refind" them. While less efficient, it makes the code more uniform.
            eval <<-EOF
              #{prefix}type_regexps_or_names#{suffix} = @specification[:#{prefix}types#{suffix}].map do |t|
                Aquarium::Utils::TypeUtils.is_type?(t) ? t.name : t
              end
              unless #{prefix}type_regexps_or_names#{suffix}.nil?
                finder_options[:"#{prefix}types#{suffix}"] = #{prefix}type_regexps_or_names#{suffix}
                exclude_finder_options[:"types#{suffix}"] = #{prefix}type_regexps_or_names#{suffix} if "#{prefix}".length > 0
              end
            EOF
          end
        end
        @candidate_types = Aquarium::Finders::TypeFinder.new.find finder_options
        @candidate_types_excluded = Aquarium::Finders::TypeFinder.new.find exclude_finder_options
        @specification[:exclude_types_calculated] = Set.new(@candidate_types_excluded.matched.keys)
      end
    
      def init_candidate_objects
        object_hash = {}
        (@specification[:objects].flatten - @specification[:exclude_objects].flatten).each do |o|
          object_hash[o] = Set.new([])
        end
        @candidate_objects = Aquarium::Finders::FinderResult.new object_hash
      end
      
      def init_candidate_join_points
        @candidate_join_points = Aquarium::Finders::FinderResult.new 
        @specification[:join_points].each do |jp|
          if jp.exists?
            @candidate_join_points.matched[jp] = Set.new([])
          else
            @candidate_join_points.not_matched[jp] = Set.new([])
          end
        end
      end
  
      def init_join_points
        @join_points_matched = Set.new
        @join_points_not_matched = Set.new
        find_join_points_for :type, (candidate_types - candidate_types_excluded), make_all_method_names
        find_join_points_for :object, candidate_objects, make_all_method_names
        add_join_points_for_candidate_join_points
        remove_excluded_join_points
      end

      def add_join_points_for_candidate_join_points 
        @join_points_matched += @candidate_join_points.matched.keys
        @join_points_not_matched += @candidate_join_points.not_matched.keys
      end
      
      def remove_excluded_join_points
        @join_points_matched.delete_if do |jp|
          join_point_excluded? jp
        end
      end
      
      def find_join_points_for type_or_object_sym, candidates, method_names
        results = find_methods_for type_or_object_sym, candidates, method_names
        add_join_points results, type_or_object_sym
      end
      
      def find_methods_for type_or_object_sym, candidates, which_methods
        return Aquarium::Finders::FinderResult::NIL_OBJECT if candidates.matched.size == 0
        Aquarium::Finders::MethodFinder.new.find type_or_object_sym => candidates.matched_keys, 
              :methods => which_methods, 
              :exclude_methods => @specification[:exclude_methods], 
              :options => @specification[:method_options].to_a
      end

      def add_join_points search_results, type_or_object_sym
        add_join_points_to @join_points_matched,     search_results.matched,     type_or_object_sym
        add_join_points_to @join_points_not_matched, search_results.not_matched, type_or_object_sym
      end
      
      def add_join_points_to which_join_points_list, results_hash, type_or_object_sym
        instance_method = @specification[:method_options].include?(:class) ? false : true
        results_hash.each_pair do |type_or_object, method_name_list|
          method_name_list.each do |method_name|
            which_join_points_list << Aquarium::Aspects::JoinPoint.new(
              type_or_object_sym => type_or_object, 
              :method_name => method_name,
              :instance_method => instance_method)
          end
        end
      end

      def make_all_method_names
        @specification[:methods] +
          Pointcut.make_attribute_method_names(@specification[:attributes], @specification[:attribute_options]) -
          @specification[:exclude_methods]
      end
  
      def self.make_attribute_readers attributes
        readers = attributes.map do |regexp_or_name|
          if regexp_or_name.kind_of? Regexp
            exp = remove_trailing_equals_and_or_dollar regexp_or_name.source
            Regexp.new(remove_leading_colon_or_at_sign(exp + '.*\b$'))
          else
            exp = remove_trailing_equals_and_or_dollar regexp_or_name.to_s
            remove_leading_colon_or_at_sign(exp.to_s)
          end
        end
        Set.new(readers.sort_by {|exp| exp.to_s})
      end  
  
      def self.make_attribute_writers attributes
        writers = attributes.map do |regexp_or_name|
          if regexp_or_name.kind_of? Regexp
            # remove the "\b$" from the end of the reader expression, if present.
            Regexp.new(remove_trailing_equals_and_or_dollar(regexp_or_name.source) + '=$')
          else
            regexp_or_name + '='
          end
        end
        Set.new(writers.sort_by {|exp| exp.to_s})
      end
  
      def self.remove_trailing_equals_and_or_dollar exp
        exp.gsub(/\=?\$?$/, '')
      end
  
      def self.remove_leading_colon_or_at_sign exp
        exp.gsub(/^\^?(@|:)/, '')
      end
    end
  end
end
