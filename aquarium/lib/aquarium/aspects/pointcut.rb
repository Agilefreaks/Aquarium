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
      #   Pointcut.new :join_points => [...] | :type{s} => [...] | :object{s} => [...] \
      #      {, :method{s} => [], :method_options => [...], \
      #      :attribute{s} => [...], :attribute_options[...]}
      # where the "{}" indicate optional elements. Most of the arguments have many
      # synonyms, shown below, to promote an English-like DSL.
      #
      # <tt>:join_points => join_point || [join_point_list]</tt>::
      # <tt>:join_point  => join_point || [join_point_list]</tt>::
      # <tt>:for_join_points => join_point || [join_point_list]</tt>::
      # <tt>:for_join_point  => join_point || [join_point_list]</tt>::
      # <tt>:on_join_points => join_point || [join_point_list]</tt>::
      # <tt>:on_join_point  => join_point || [join_point_list]</tt>::
      # <tt>:within_join_points => join_point || [join_point_list]</tt>::
      # <tt>:within_join_point  => join_point || [join_point_list]</tt>::
      #   One or an array of join_points.
      #
      # <tt>:types => type || [type_list]</tt>::
      # <tt>:type  => type || [type_list]</tt>::
      # <tt>:for_types => type || [type_list]</tt>::
      # <tt>:for_type  => type || [type_list]</tt>::
      # <tt>:on_types => type || [type_list]</tt>::
      # <tt>:on_type  => type || [type_list]</tt>::
      # <tt>:within_types => type || [type_list]</tt>::
      # <tt>:within_type  => type || [type_list]</tt>::
      #   One or an array of types, type names and/or type regular expessions to match. 
      #
      # <tt>:types_and_descendents => type || [type_list]</tt>::
      # <tt>:type_and_descendents  => type || [type_list]</tt>::
      # <tt>:types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:type_and_ancestors    => type || [type_list]</tt>::
      # <tt>:for_types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:for_type_and_ancestors    => type || [type_list]</tt>::
      # <tt>:on_types_and_descendents => type || [type_list]</tt>::
      # <tt>:on_type_and_descendents  => type || [type_list]</tt>::
      # <tt>:on_types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:on_type_and_ancestors    => type || [type_list]</tt>::
      # <tt>:within_types_and_descendents => type || [type_list]</tt>::
      # <tt>:within_type_and_descendents  => type || [type_list]</tt>::
      # <tt>:within_types_and_ancestors   => type || [type_list]</tt>::
      # <tt>:within_type_and_ancestors    => type || [type_list]</tt>::
      #   One or an array of types and either their descendents or ancestors. 
      #   If you want both the descendents _and_ ancestors, use both options.
      #
      # <tt>:objects => object || [object_list]</tt>::
      # <tt>:object  => object || [object_list]</tt>::
      # <tt>:for_objects => object || [object_list]</tt>::
      # <tt>:for_object  => object || [object_list]</tt>::
      # <tt>:on_objects => object || [object_list]</tt>::
      # <tt>:on_object  => object || [object_list]</tt>::
      # <tt>:within_objects => object || [object_list]</tt>::
      # <tt>:within_object  => object || [object_list]</tt>::
      #   Objects to match.
      #    
      # <tt>:default_objects => object || [object_list]</tt>::
      # <tt>:default_object => object || [object_list]</tt>::
      #   An "internal" flag used by AspectDSL#pointcut when no object or type is specified, 
      #   the value of :default_objects will be used, if defined. AspectDSL#pointcut sets the 
      #   value to self, so that the user doesn't have to in the appropriate contexts.
      #   This flag is subject to change, so don't use it explicitly!
      #
      # <tt>:methods => method || [method_list]</tt>::
      # <tt>:method  => method || [method_list]</tt>::
      # <tt>:within_methods => method || [method_list]</tt>::
      # <tt>:within_method  => method || [method_list]</tt>::
      # <tt>:calling  => method || [method_list]</tt>::
      # <tt>:calls_to  => method || [method_list]</tt>::
      # <tt>:invoking  => method || [method_list]</tt>::
      # <tt>:invocations_of  => method || [method_list]</tt>::
      # <tt>:sending_message_to  => method || [method_list]</tt>::
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
      # <tt>:changing => attribute || [attribute_list]</tt>::
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
      #   <tt>:writing => ...</tt> and <tt>:changing => ...</tt> are synonymous with <tt>:attributes => ..., 
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
      #   Also <tt>exclude_{synonyms}</tt> of the same options...
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
      # Pointcut.new also accepts all the "universal" options documented in OptionsUtils.
      def initialize options = {} 
        init_specification options, CANONICAL_OPTIONS
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
        (specification == other.specification && 
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

      CANONICAL_OPTIONS = {
        "types"                 => %w[type class classes module modules],
        "types_and_descendents" => %w[type_and_descendents class_and_descendents classes_and_descendents module_and_descendents modules_and_descendents],
        "types_and_ancestors"   => %w[type_and_ancestors class_and_ancestors classes_and_ancestors module_and_ancestors modules_and_ancestors],
        "objects"               => %w[object],
        "join_points"           => %w[join_point],
        "methods"               => %w[method within_method within_methods calling invoking calls_to invocations_of sending_message_to sending_messages_to],
        "attributes"            => %w[attribute accessing],
        "method_options"        => %w[method_option restricting_methods_to], 
        "attribute_options"     => %w[attribute_option],
        "default_objects"       => %w[default_object]
      }
      %w[types types_and_descendents types_and_ancestors objects join_points ].each do |thing|
        roots = CANONICAL_OPTIONS[thing].dup + [thing]
        CANONICAL_OPTIONS["exclude_#{thing}"] = roots.map {|x| "exclude_#{x}"}
        %w[for on in within].each do |prefix|
          roots.each do |root|
            CANONICAL_OPTIONS[thing] << "#{prefix}_#{root}" 
          end
        end
      end
      CANONICAL_OPTIONS["methods"].dup.each do |synonym|
        CANONICAL_OPTIONS["methods"] << "#{synonym}_methods_matching"
      end
      CANONICAL_OPTIONS["exclude_methods"] = []
      CANONICAL_OPTIONS["methods"].each do |synonym|
        CANONICAL_OPTIONS["exclude_methods"] << "exclude_#{synonym}"
      end
      CANONICAL_OPTIONS["exclude_pointcuts"] = ["exclude_pointcut"] + 
        %w[for on in within].map {|prefix| ["exclude_#{prefix}_pointcuts", "exclude_#{prefix}_pointcut"]}.flatten
            
      ATTRIBUTE_OPTIONS = %w[reading writing changing]
      
      ALL_ALLOWED_OPTIONS = ATTRIBUTE_OPTIONS +
          CANONICAL_OPTIONS.keys.inject([]) {|ary,i| ary << i << CANONICAL_OPTIONS[i]}.flatten

      ALL_ALLOWED_OPTION_SYMBOLS = ALL_ALLOWED_OPTIONS.map {|o| o.intern}
         
      def all_allowed_option_symbols
        ALL_ALLOWED_OPTION_SYMBOLS
      end

      CANONICAL_OPTIONS.keys.each do |name|
        module_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}_given
            @specification[:#{name}]
          end
  
          def #{name}_given?
            not (#{name}_given.nil? or #{name}_given.empty?)
          end
        EOF
      end

      def self.make_attribute_reading_writing_options options_hash
        result = {}
        [:writing, :changing, :reading].each do |attr_key|
          unless options_hash[attr_key].nil? or options_hash[attr_key].empty?
            result[:attributes] ||= Set.new([])
            result[:attribute_options] ||= Set.new([])
            result[:attributes].merge(Aquarium::Utils::ArrayUtils.make_array(options_hash[attr_key]))
            attr_opt = attr_key == :reading ? :readers : :writers
            result[:attribute_options] << attr_opt
          end
        end
        result
      end
            
      protected
  
      attr_writer :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_types_excluded, :candidate_objects, :candidate_join_points

      def init_type_specific_specification original_options, options_hash
        @specification.merge! Pointcut.make_attribute_reading_writing_options(options_hash)
        # Map the method options to their canonical values:
        @specification[:method_options] = Aquarium::Finders::MethodFinder.init_method_options(@specification[:method_options])
        use_default_objects_if_defined unless (types_given? || objects_given?)

        raise Aquarium::Utils::InvalidOptions.new(":all is not yet supported for :attributes.") if @specification[:attributes] == Set.new([:all])
        if options_hash[:reading] and (options_hash[:writing] or options_hash[:changing])
          unless options_hash[:reading].eql?(options_hash[:writing]) or options_hash[:reading].eql?(options_hash[:changing])
            raise Aquarium::Utils::InvalidOptions.new(":reading and :writing/:changing can only be used together if they refer to the same set of attributes.") 
          end
        end
        init_methods_specification options_hash
      end
    
      def init_methods_specification options
        match_all_methods if ((no_methods_specified and no_attributes_specified) or all_methods_specified)
      end

      def match_all_methods
        @specification[:methods] = Set.new([:all])
      end
      
      def no_methods_specified
        @specification[:methods].nil? or @specification[:methods].empty?
      end
      
      def all_methods_specified
        methods_spec = @specification[:methods].to_a
        methods_spec.include?(:all) or methods_spec.include?(:all_methods)
      end
      
      def no_attributes_specified
        @specification[:attributes].nil? or @specification[:attributes].empty?
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
              :options => method_options
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
