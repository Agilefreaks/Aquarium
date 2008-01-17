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
      # <tt>:reading   => attribute || [attribute_list]</tt>::
      # <tt>:writing   => attribute || [attribute_list]</tt>::
      # <tt>:accessing => attribute || [attribute_list]</tt>::
      #   One or an array of attribute names and/or regular expessions to match. 
      #   This is syntactic sugar for the corresponding attribute readers and/or writers
      #   methods. 
      #   If <tt>:reading</tt> is specified, just attribute readers are matched.
      #   If <tt>:writing</tt> is specified, just attribute writers are matched.
      #   If <tt>:accessing</tt> is specified, both readers and writers are matched.
      #   Any matches will be joined with the matched <tt>:methods.</tt>.
      #
      # <tt>:attributes => attribute || [attribute_list]</tt>::
      # <tt>:attribute  => attribute || [attribute_list]</tt>::
      #   One or an array of attribute names and/or regular expessions to match. 
      #   This is syntactic sugar for the corresponding attribute readers and/or writers
      #   methods, as specified using the <tt>:attrbute_options</tt>. Any matches will be
      #   joined with the matched <tt>:methods.</tt>.
      #
      # <tt>:attribute_options => [options]</tt>::
      #   One or more of <tt>:readers</tt>, <tt>:reader</tt> (synonymous), 
      #   <tt>:writers</tt>, and/or <tt>:writer</tt> (synonymous). By default, both
      #   readers and writers are matched. 
      #   <tt>:reading => ...</tt> is synonymous with <tt>:attributes => ..., 
      #   :attribute_options => [:readers]</tt>.
      #   <tt>:writing => ...</tt> is synonymous with <tt>:attributes => ..., 
      #   :attribute_options => [:writers]</tt>.
      #   <tt>:accessing => ...</tt> is synonymous with <tt>:attributes => ...</tt>.
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

      protected
  
      attr_writer :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_types_excluded, :candidate_objects, :candidate_join_points

      CANONICAL_OPTIONS = {
        "types"                 => %w[type on_type on_types],
        "objects"               => %w[object on_object on_objects],
        "join_points"           => %w[join_point on_join_point on_join_points],
        "methods"               => %w[method calling invoking calls_to sending_message_to],
        "attributes"            => %w[attribute accessing],
        "method_options"        => %w[method_option], 
        "attribute_options"     => %w[attribute_option],
        "types_and_descendents" => %w[type_and_descendents on_type_and_descendents on_types_and_descendents],
        "types_and_ancestors"   => %w[type_and_ancestors on_type_and_ancestors on_types_and_ancestors],
        "default_objects"       => %w[default_object]
      }
      %w[types objects join_points methods types_and_descendents types_and_ancestors].each do |key|
        CANONICAL_OPTIONS["exclude_#{key}"] = CANONICAL_OPTIONS[key].map {|x| "exclude_#{x}"}
      end
      CANONICAL_OPTIONS["exclude_pointcuts"] = %w[exclude_pointcut exclude_on_pointcut exclude_on_pointcuts]
         
      ALL_ALLOWED_OPTIONS = %w[reading writing changing] +
          CANONICAL_OPTIONS.keys.inject([]) {|ary,i| ary << i << CANONICAL_OPTIONS[i]}.flatten

      ALL_ALLOWED_OPTION_SYMBOLS = ALL_ALLOWED_OPTIONS.map {|o| o.intern}

      def init_specification options
        @specification = {}
        options ||= {} 
        validate_options options
        CANONICAL_OPTIONS.keys.each do |key|
          all_related_options = make_array(options[key.intern]) || []
          CANONICAL_OPTIONS[key].inject(all_related_options) do |ary, o| 
            ary << options[o.intern] if options[o.intern]
            ary
          end
          @specification[key.intern] = Set.new(make_array(all_related_options))
        end
        unless options[:reading].nil? or options[:reading].empty?
          @specification[:attributes] += Set.new(make_array(options[:reading]))
          @specification[:attribute_options] += Set.new([:readers])
        end
        [:writing, :changing].each do |attr_opt|
          unless options[attr_opt].nil? or options[attr_opt].empty?
            @specification[:attributes] += Set.new(make_array(options[attr_opt]))
            @specification[:attribute_options] += Set.new([:writers])
          end
        end
        
        use_default_object_if_defined unless (types_given? || objects_given?)

        raise Aquarium::Utils::InvalidOptions.new(":all is not yet supported for :attributes.") if @specification[:attributes] == Set.new([:all])
        init_methods_specification options
      end
    
      def init_methods_specification options
        match_all_methods if no_methods_specified and no_attributes_specified
      end

      def match_all_methods
        @specification[:methods] = Set.new([:all])
      end
      
      def no_methods_specified
        @specification[:methods].nil? or @specification[:methods].empty?
      end
      
      def no_attributes_specified
        @specification[:attributes].nil? or @specification[:attributes].empty?
      end
      
      def validate_options options
        unknowns = options.keys - ALL_ALLOWED_OPTION_SYMBOLS
        raise Aquarium::Utils::InvalidOptions.new("Unknown options specified: #{unknowns.inspect}") if unknowns.size > 0
      end
  
      CANONICAL_OPTIONS.keys.each do |name|
        class_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}_given
            @specification[:#{name}]
          end
  
          def #{name}_given?
            not (#{name}_given.nil? or #{name}_given.empty?)
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
            make_attribute_method_names(@specification[:attributes], @specification[:attribute_options]) -
            @specification[:exclude_methods]
      end
  
      def make_attribute_method_names attribute_name_regexps_or_names, attribute_options = []
        readers = make_attribute_readers attribute_name_regexps_or_names
        return readers if read_only attribute_options 

        writers = make_attribute_writers readers
        return writers if write_only attribute_options
        return readers + writers
      end
  
      def make_attribute_readers attributes
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
  
      def make_attribute_writers attributes
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
  
      def read_only attribute_options
        read_option(attribute_options) && !write_option(attribute_options)
      end
  
      def write_only attribute_options
        write_option(attribute_options) && !read_option(attribute_options)
      end
  
      def read_option attribute_options
        attribute_options.include?(:readers) or attribute_options.include?(:reader)
      end
  
      def write_option attribute_options
        attribute_options.include?(:writers) or attribute_options.include?(:writer)
      end
  
      def remove_trailing_equals_and_or_dollar exp
        exp.gsub(/\=?\$?$/, '')
      end
  
      def remove_leading_colon_or_at_sign exp
        exp.gsub(/^\^?(@|:)/, '')
      end
    end
  end
end
