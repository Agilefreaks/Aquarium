require 'set'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/exclusion_handler'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/finders/finder_result'
require 'aquarium/finders/type_finder'
require 'aquarium/finders/method_finder'
require 'aquarium/aspects/default_objects_handler'

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
      include Aquarium::Utils::OptionsUtils
      include Aquarium::Utils::SetUtils
      include ExclusionHandler
      include DefaultObjectsHandler

      attr_reader :specification

      # Construct a Pointcut for methods in types or objects.
      #   Pointcut.new :join_points => [...] | :type{s} => [...] | :object{s} => [...]
      #      {, :method{s} => [], :method_options => [...],
      #      :attribute{s} => [...], :attribute_options[...]}
      # where the "{}" indicate optional elements. Most of the arguments have many
      # synonyms, shown below, to promote an English-like DSL.
      #
      # The options include the following.
      # ==== Join Points
      # Specify one or an array of join_points.
      # * <tt>:join_points => join_point || [join_point_list]</tt>
      # * <tt>:join_point  => join_point || [join_point_list]</tt>
      # * <tt>:for_join_points => join_point || [join_point_list]</tt>
      # * <tt>:for_join_point  => join_point || [join_point_list]</tt>
      # * <tt>:on_join_points => join_point || [join_point_list]</tt>
      # * <tt>:on_join_point  => join_point || [join_point_list]</tt>
      # * <tt>:within_join_points => join_point || [join_point_list]</tt>
      # * <tt>:within_join_point  => join_point || [join_point_list]</tt>
      #
      # ===== Types
      # Specify a type, type name, type name regular expression or an array of the same. (Mixed is allowed.)
      # * <tt>:types => type || [type_list]</tt>
      # * <tt>:type  => type || [type_list]</tt>
      # * <tt>:for_types => type || [type_list]</tt>
      # * <tt>:for_type  => type || [type_list]</tt>
      # * <tt>:on_types => type || [type_list]</tt>
      # * <tt>:on_type  => type || [type_list]</tt>
      # * <tt>:within_types => type || [type_list]</tt>
      # * <tt>:within_type  => type || [type_list]</tt>
      #
      # ===== Types and Ancestors or Descendents
      # Specify a type, type name, type name regular expression or an array of the same. (Mixed is allowed.)
      # The ancestors or descendents will also be found. To find <i>both</i> ancestors and descendents, use
      # both options.
      # * <tt>:types_and_descendents => type || [type_list]</tt>
      # * <tt>:type_and_descendents  => type || [type_list]</tt>
      # * <tt>:types_and_ancestors   => type || [type_list]</tt>
      # * <tt>:type_and_ancestors    => type || [type_list]</tt>
      # * <tt>:for_types_and_ancestors   => type || [type_list]</tt>
      # * <tt>:for_type_and_ancestors    => type || [type_list]</tt>
      # * <tt>:on_types_and_descendents => type || [type_list]</tt>
      # * <tt>:on_type_and_descendents  => type || [type_list]</tt>
      # * <tt>:on_types_and_ancestors   => type || [type_list]</tt>
      # * <tt>:on_type_and_ancestors    => type || [type_list]</tt>
      # * <tt>:within_types_and_descendents => type || [type_list]</tt>
      # * <tt>:within_type_and_descendents  => type || [type_list]</tt>
      # * <tt>:within_types_and_ancestors   => type || [type_list]</tt>
      # * <tt>:within_type_and_ancestors    => type || [type_list]</tt>
      #
      # ===== Types and Nested Types
      # Specify a type, type name, type name regular expression or an array of the same. (Mixed is allowed.)
      # The nested (enclosed) types will also be found.
      # * <tt>:types_and_nested_types => type || [type_list]</tt>
      # * <tt>:type_and_nested_types  => type || [type_list]</tt>
      # * <tt>:types_and_nested => type || [type_list]</tt>
      # * <tt>:type_and_nested  => type || [type_list]</tt>
      # * <tt>:for_types_and_nested_types => type || [type_list]</tt>
      # * <tt>:for_type_and_nested_types  => type || [type_list]</tt>
      # * <tt>:for_types_and_nested => type || [type_list]</tt>
      # * <tt>:for_type_and_nested  => type || [type_list]</tt>
      # * <tt>:on_types_and_nested_types => type || [type_list]</tt>
      # * <tt>:on_type_and_nested_types  => type || [type_list]</tt>
      # * <tt>:on_types_and_nested => type || [type_list]</tt>
      # * <tt>:on_type_and_nested  => type || [type_list]</tt>
      # * <tt>:within_types_and_nested_types => type || [type_list]</tt>
      # * <tt>:within_type_and_nested_types  => type || [type_list]</tt>
      # * <tt>:within_types_and_nested => type || [type_list]</tt>
      # * <tt>:within_type_and_nested  => type || [type_list]</tt>
      #
      # ===== Objects
      # * <tt>:objects => object || [object_list]</tt>
      # * <tt>:object  => object || [object_list]</tt>
      # * <tt>:for_objects => object || [object_list]</tt>
      # * <tt>:for_object  => object || [object_list]</tt>
      # * <tt>:on_objects => object || [object_list]</tt>
      # * <tt>:on_object  => object || [object_list]</tt>
      # * <tt>:within_objects => object || [object_list]</tt>
      # * <tt>:within_object  => object || [object_list]</tt>
      #    
      # ===== "Default" Objects
      # An "internal" flag used by Aspect::DSL#pointcut. When no object or type is specified 
      # explicitly, the value of :default_objects will be used, if defined. Aspect::DSL#pointcut
      # sets the value to +self+, so the user doesn't have to specify a type or object in the
      # contexts where that would be useful, <i>e.g.,</i> pointcuts defined within a type for join points
      # within itself. *WARNING*: This flag is subject to change, so don't use it explicitly!
      # * <tt>:default_objects => object || [object_list]</tt>
      # * <tt>:default_object => object || [object_list]</tt>
      #
      # ===== Methods
      # A method name, name regular expession or an array of the same. 
      # By default, if neither <tt>:methods</tt> nor <tt>:attributes</tt> are specified, all public instance methods
      # will be found, with the method option <tt>:exclude_ancestor_methods</tt> implied, unless explicit method 
      # options are given.
      # * <tt>:methods => method || [method_list]</tt>
      # * <tt>:method  => method || [method_list]</tt>
      # * <tt>:within_methods => method || [method_list]</tt>
      # * <tt>:within_method  => method || [method_list]</tt>
      # * <tt>:calling  => method || [method_list]</tt>
      # * <tt>:calls_to  => method || [method_list]</tt>
      # * <tt>:invoking  => method || [method_list]</tt>
      # * <tt>:invocations_of  => method || [method_list]</tt>
      # * <tt>:sending_message_to  => method || [method_list]</tt>
      #
      # ===== Method Options
      # One or more options supported by Aquarium::Finders::MethodFinder. The <tt>:exclude_ancestor_methods</tt>
      # option is most useful.
      # * <tt>:method_options => [options]</tt>
      #
      # ===== Attributes
      # An attribute name, regular expession or array of the same. 
      # *WARNING* This is syntactic sugar for the corresponding attribute readers and/or writers
      # methods. The actual attribute accesses are not advised, which can lead to unexpected
      # behavior. A goal before V1.0 is to support actual attribute accesses, if possible.  
      # * <tt>:attributes => attribute || [attribute_list]</tt>
      # * <tt>:attribute  => attribute || [attribute_list]</tt>
      # * <tt>:reading   => attribute || [attribute_list]</tt>
      # * <tt>:writing   => attribute || [attribute_list]</tt>
      # * <tt>:changing => attribute || [attribute_list]</tt>
      # * <tt>:accessing => attribute || [attribute_list]</tt>
      # If <tt>:reading</tt> is specified, just attribute readers are matched.
      # If <tt>:writing</tt> is specified, just attribute writers are matched.
      # If <tt>:accessing</tt> is specified, both readers and writers are matched.
      # Any matches will be joined with the matched <tt>:methods.</tt>.
      #
      # ===== Attribute Options
      # One or more of <tt>:readers</tt>, <tt>:reader</tt> (synonymous), 
      # <tt>:writers</tt>, and/or <tt>:writer</tt> (synonymous). By default, both
      # readers and writers are matched. 
      # <tt>:reading => ...</tt> is synonymous with <tt>:attributes => ..., 
      # :attribute_options => [:readers]</tt>.
      # <tt>:writing => ...</tt> and <tt>:changing => ...</tt> are synonymous with <tt>:attributes => ..., 
      # :attribute_options => [:writers]</tt>.
      # <tt>:accessing => ...</tt> is synonymous with <tt>:attributes => ...</tt>.
      # * <tt>:attribute_options => [options]</tt>
      #
      # ==== Exclusion Options
      # Exclude the specified "things" from the matched join points. If pointcuts are
      # excluded, they should be subsets of the matched pointcuts. Otherwise, the
      # resulting pointcut will be empty!
      # * <tt>:exclude_pointcuts   => pc || [pc_list]</tt>
      # * <tt>:exclude_pointcut    => pc || [pc_list]</tt>
      # * <tt>:exclude_join_points => jp || [jp_list]</tt>
      # * <tt>:exclude_join_point  => jp || [jp_list]</tt>
      # * <tt>:exclude_types       => type || [type_list]</tt>
      # * <tt>:exclude_types       => type || [type_list]</tt>
      # * <tt>:exclude_type        => type || [type_list]</tt>
      # * <tt>:exclude_types_and_descendents => type || [type_list]</tt>
      # * <tt>:exclude_type_and_descendents  => type || [type_list]</tt>
      # * <tt>:exclude_types_and_ancestors   => type || [type_list]</tt>
      # * <tt>:exclude_type_and_ancestors    => type || [type_list]</tt>
      # * <tt>:exclude_types_and_nested_types => type || [type_list]</tt>
      # * <tt>:exclude_type_and_nested_types  => type || [type_list]</tt>
      # * <tt>:exclude_types_and_nested       => type || [type_list]</tt>
      # * <tt>:exclude_type_and_nested        => type || [type_list]</tt>
      # * <tt>:exclude_objects     => object || [object_list]</tt>
      # * <tt>:exclude_object      => object || [object_list]</tt>
      # * <tt>:exclude_methods     => method || [method_list]</tt>
      # * <tt>:exclude_method      => method || [method_list]</tt>
      # * <tt>:exclude_attributes  => attribute || [attribute_list]</tt>
      # * <tt>:exclude_attribute   => attribute || [attribute_list]</tt>
      # The <tt>exclude_</tt> prefix works with the synonyms of the options shown.
      #
      # Pointcut.new also accepts all the "universal" options documented in Aquarium::Utils::OptionsUtils.
      def initialize options = {} 
        init_specification options, CANONICAL_OPTIONS, (ATTRIBUTE_OPTIONS_VALUES + Advice::KINDS_IN_PRIORITY_ORDER) do 
          finish_specification_initialization
        end
        return if noop
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
        (self.class === other &&
         specification == other.specification && 
         candidate_types == other.candidate_types && 
         candidate_types_excluded == other.candidate_types_excluded && 
         candidate_objects == other.candidate_objects && 
         join_points_not_matched == other.join_points_not_matched &&
         join_points_matched == other.join_points_matched)  # not_matched is probably smaller, so do first.
      end
  
      alias :== :eql?
  
      def empty?
        return join_points_matched.empty? && join_points_not_matched.empty?
      end
  
      def inspect
        "Pointcut: {specification: #{specification.inspect}, candidate_types: #{candidate_types.inspect}, candidate_types_excluded: #{candidate_types_excluded.inspect}, candidate_objects: #{candidate_objects.inspect}, join_points_matched: #{join_points_matched.inspect}, join_points_not_matched: #{join_points_not_matched.inspect}}"
      end
  
      alias to_s inspect

      POINTCUT_CANONICAL_OPTIONS = {
        "default_objects"       => %w[default_object],
        "join_points"           => %w[join_point],
        "exclude_pointcuts"     => %w[exclude_pointcut],
        "attributes"            => %w[attribute accessing],
        "attribute_options"     => %w[attribute_option],
      }
      add_prepositional_option_variants_for "join_points", POINTCUT_CANONICAL_OPTIONS
      add_exclude_options_for               "join_points", POINTCUT_CANONICAL_OPTIONS
      Aquarium::Utils::OptionsUtils.universal_prepositions.each do |prefix|
        POINTCUT_CANONICAL_OPTIONS["exclude_pointcuts"] += ["exclude_#{prefix}_pointcuts", "exclude_#{prefix}_pointcut"]
      end
      CANONICAL_OPTIONS = Aquarium::Finders::TypeFinder::CANONICAL_OPTIONS.merge(
        Aquarium::Finders::MethodFinder::METHOD_FINDER_CANONICAL_OPTIONS.merge(POINTCUT_CANONICAL_OPTIONS))

      ATTRIBUTE_OPTIONS_VALUES = %w[reading writing changing]

      canonical_options_given_methods CANONICAL_OPTIONS
      canonical_option_accessor CANONICAL_OPTIONS

      def self.make_attribute_reading_writing_options options_hash
        result = {}
        [:writing, :changing, :reading].each do |attr_key|
          next if options_hash[attr_key].nil? or options_hash[attr_key].empty?
          result[:attributes] ||= Set.new([])
          result[:attribute_options] ||= Set.new([])
          result[:attributes].merge(Aquarium::Utils::ArrayUtils.make_array(options_hash[attr_key]))
          attr_opt = attr_key == :reading ? :readers : :writers
          result[:attribute_options] << attr_opt
        end
        result
      end
            
      def finish_specification_initialization
        @specification.merge! Pointcut.make_attribute_reading_writing_options(@original_options)
        # Map the method options to their canonical values:
        @specification[:method_options] = Aquarium::Finders::MethodFinder.init_method_options(@specification[:method_options])
        use_default_objects_if_defined unless any_type_related_options_given?
        Pointcut::validate_attribute_options @specification, @original_options
        init_methods_specification
      end
    
      def init_methods_specification
        match_all_methods if ((no_methods_specified? and no_attributes_specified?) or all_methods_specified?)
      end

      def any_type_related_options_given?
        objects_given? or join_points_given? or types_given? or types_and_descendents_given? or types_and_ancestors_given? or types_and_nested_types_given?
      end
      
      def self.validate_attribute_options spec_hash, options_hash
        raise Aquarium::Utils::InvalidOptions.new(":all is not yet supported for :attributes.") if spec_hash[:attributes] == Set.new([:all])
        if options_hash[:reading] and (options_hash[:writing] or options_hash[:changing])
          unless options_hash[:reading].eql?(options_hash[:writing]) or options_hash[:reading].eql?(options_hash[:changing])
            raise Aquarium::Utils::InvalidOptions.new(":reading and :writing/:changing can only be used together if they refer to the same set of attributes.") 
          end
        end
      end
      
      protected
  
      attr_writer :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_types_excluded, :candidate_objects, :candidate_join_points

      def match_all_methods
        @specification[:methods] = Set.new([:all])
      end
      
      def no_methods_specified?
        @specification[:methods].nil? or @specification[:methods].empty?
      end
      
      def all_methods_specified?
        methods_spec = @specification[:methods].to_a
        methods_spec.include?(:all) or methods_spec.include?(:all_methods)
      end
      
      def no_attributes_specified?
        @specification[:attributes].nil? or @specification[:attributes].empty?
      end
      
      private 
  
      def init_candidate_types 
        finder_options = {}
        exclude_finder_options = {}
        ['', 'exclude_'].each do |prefix|
          ['', '_and_ancestors', '_and_descendents', '_and_nested_types'].each do |suffix|
            # Because the user might be asking for descendents, ancestors and/or nested types, we convert
            # explicitly-specified types into names, then "refind" them. While less efficient, it makes 
            # the code more uniform.
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
        types = candidate_types - candidate_types_excluded
        method_names = make_method_names
        attribute_method_names = make_attribute_method_names
        unless types.empty?
          find_join_points_for(:type, types, method_names) unless method_names.empty?
          find_join_points_for(:type, types, attribute_method_names) unless attribute_method_names.empty?
        end
        unless candidate_objects.empty?
          find_join_points_for(:object, candidate_objects, method_names) unless method_names.empty?
          find_join_points_for(:object, candidate_objects, attribute_method_names) unless attribute_method_names.empty?
        end
        subtract_attribute_writers if attributes_read_only?
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
              :methods => which_methods.to_a, 
              :exclude_methods => @specification[:exclude_methods], 
              :method_options => method_options
      end

      def add_join_points search_results, type_or_object_sym
        add_join_points_to @join_points_matched,     search_results.matched,     type_or_object_sym
        add_join_points_to @join_points_not_matched, search_results.not_matched, type_or_object_sym
      end
      
      def add_join_points_to which_join_points_list, results_hash, type_or_object_sym
        results_hash.each_pair do |type_or_object, method_name_list|
          method_name_list.each do |method_name|
            which_join_points_list << Aquarium::Aspects::JoinPoint.new(
              type_or_object_sym => type_or_object, 
              :method_name => method_name,
              :instance_method => is_instance_methods?)
          end
        end
      end

      def subtract_attribute_writers
        @join_points_matched.reject! do |jp|
          jp.method_name.to_s[-1..-1] == '='
        end
      end
      
      def is_instance_methods?
        not @specification[:method_options].include? :class
      end
      
      def make_method_names
        @specification[:methods] - @specification[:exclude_methods]
      end
  
      def make_attribute_method_names
        readers = make_attribute_readers 
        return readers if attributes_read_only?

        writers = make_attribute_writers readers
        return writers if attributes_write_only?
        return readers + writers
      end
  
      # Because Ruby 1.8 regexp library doesn't support negative look behinds, we really
      # can't set the regular expression to exclude a trailing = reliably. Instead,
      # #init_join_points above will remove any writer methods, if necessary.
      def make_attribute_readers 
        readers = @specification[:attributes].map do |regexp_or_name|
          expr1 = regexp_or_name.kind_of?(Regexp) ? regexp_or_name.source : regexp_or_name.to_s
          expr = remove_trailing_equals_and_or_dollar(remove_leading_colon_or_at_sign(expr1))
          if regexp_or_name.kind_of? Regexp
            Regexp.new(remove_leading_colon_or_at_sign(expr))
          else
            expr
          end
        end
        Set.new(readers.sort_by {|exp| exp.to_s})
      end  
        
      def make_attribute_writers reader_methods
        writers = reader_methods.map do |regexp_or_name|
          expr = regexp_or_name.kind_of?(Regexp) ? regexp_or_name.source : regexp_or_name.to_s
          if regexp_or_name.kind_of? Regexp
            Regexp.new(expr+'.*=$')
          else
            expr + '='
          end
        end
        Set.new(writers.sort_by {|exp| exp.to_s})
      end
  
      def attributes_read_only?
        read_option && !write_option
      end
  
      def attributes_write_only?
        write_option && !read_option
      end
  
      def read_option 
        @specification[:attribute_options].include?(:readers) or @specification[:attribute_options].include?(:reader)
      end
  
      def write_option 
        @specification[:attribute_options].include?(:writers) or @specification[:attribute_options].include?(:writer)
      end
  
      def method_options
        @specification[:method_options].to_a.map {|mo| mo == :all_methods ? :all : mo }
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
