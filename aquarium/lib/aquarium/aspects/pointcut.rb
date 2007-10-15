require 'set'
require 'aquarium/aspects/join_point'
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
      def initialize options = {} 
        init_specification options
        init_candidate_types 
        init_candidate_objects
        init_candidate_join_points
        init_join_points
      end
  
      attr_reader :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_objects, :candidate_join_points
  
      # Two Considered equivalent only if the same join points matched and not_matched sets are equal, 
      # the specifications are equal, and the candidate types and candidate objects are equal.
      # if you care only about the matched join points, then just compare #join_points_matched
      def eql? other
        object_id == other.object_id ||
        (specification == other.specification && 
         candidate_types == other.candidate_types && 
         candidate_objects == other.candidate_objects && 
         join_points_matched == other.join_points_matched &&
         join_points_not_matched == other.join_points_not_matched) 
      end
  
      alias :== :eql?
  
      def empty?
        return join_points_matched.empty? && join_points_not_matched.empty?
      end
  
      def inspect
        "Pointcut: {specification: #{specification.inspect}, candidate_types: #{candidate_types.inspect}, candidate_objects: #{candidate_objects.inspect}, join_points_matched: #{join_points_matched.inspect}, join_points_not_matched: #{join_points_not_matched.inspect}}"
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
  
      attr_writer :join_points_matched, :join_points_not_matched, :specification, :candidate_types, :candidate_objects, :candidate_join_points

      def init_specification options
        @specification = {}
        options ||= {} 
        validate_options options
        @specification[:method_options] = Set.new(make_array(options[:method_options]))
        @specification[:attribute_options] = Set.new(make_array(options[:attribute_options]) )
        @specification[:types]   = Set.new(make_array(options[:types], options[:type]))
        @specification[:objects] = Set.new(make_array(options[:objects], options[:object]))
        @specification[:join_points] = Set.new(make_array(options[:join_points], options[:join_point]))
        @specification[:exclude_types] = Set.new(make_array(options[:exclude_type], options[:exclude_types]))
        @specification[:exclude_objects] = Set.new(make_array(options[:exclude_object], options[:exclude_objects]))
        @specification[:exclude_join_points] = Set.new(make_array(options[:exclude_join_point], options[:exclude_join_points]))
        @specification[:exclude_methods] = Set.new(make_array(options[:exclude_method], options[:exclude_methods]))
        @specification[:default_object] = Set.new(make_array(options[:default_object]))
        use_default_object_if_defined unless (types_given? || objects_given?)
        @specification[:attributes] = Set.new(make_array(options[:attributes], options[:attribute]))
        raise Aquarium::Utils::InvalidOptions.new(":all is not yet supported for :attributes.") if @specification[:attributes] == Set.new([:all])
        init_methods_specification options
      end
  
      def init_methods_specification options
        @specification[:methods] = Set.new(make_array(options[:methods], options[:method]))
        @specification[:methods].add(:all) if @specification[:methods].empty? and @specification[:attributes].empty?
      end
      
      def validate_options options
        knowns = %w[object objects type types join_point join_points 
          exclude_object exclude_objects exclude_type exclude_types exclude_join_point exclude_join_points exclude_method exclude_methods
          method methods attribute attributes 
          method_options attribute_options default_object].map {|x| x.intern}
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

      %w[types objects join_points methods].each do |name|
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
        explicit_types, type_regexps_or_names = @specification[:types].partition do |type|
          Aquarium::Utils::TypeUtils.is_type? type
        end
        excluded_explicit_types, excluded_type_regexps_or_names = @specification[:exclude_types].partition do |type|
          Aquarium::Utils::TypeUtils.is_type? type
        end
        possible_types = Aquarium::Finders::TypeFinder.new.find :types => type_regexps_or_names, :exclude_types => excluded_type_regexps_or_names
        possible_types.append_matched(make_hash(explicit_types) {|x| Set.new([])})
        @candidate_types = possible_types - Aquarium::Finders::TypeFinder.new.find(:types => excluded_type_regexps_or_names)
        @candidate_types.matched.delete_if {|type, value| excluded_explicit_types.include? type}
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
        find_join_points_for :type, candidate_types, make_all_method_names
        find_join_points_for :object, candidate_objects, make_all_method_names
        add_join_points_for_candidate_join_points
      end

      def add_join_points_for_candidate_join_points 
        @join_points_matched += @candidate_join_points.matched.keys.find_all do |jp|
          not (is_excluded_join_point?(jp) or is_excluded_type_or_object?(jp.type_or_object) or is_excluded_method?(jp.method_name))
        end
        @join_points_not_matched += @candidate_join_points.not_matched.keys
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
  
      def is_excluded_join_point? jp
        @specification[:exclude_join_points].include? jp
      end
      
      def is_excluded_type_or_object? type_or_object
        return true if @specification[:exclude_objects].include?(type_or_object)
        @specification[:exclude_types].find do |t|
          case t
          when String: type_or_object.name.eql?(t)
          when Symbol: type_or_object.name.eql?(t.to_s)
          when Regexp: type_or_object.name =~ t
          else         type_or_object == t
          end
        end
      end
       
      def is_excluded_method? method
        is_explicitly_excluded_method?(method) or matches_excluded_method_regex?(method)
      end
      
      def is_explicitly_excluded_method? method
        @specification[:exclude_methods].include? method
      end
      
      def matches_excluded_method_regex? method
        regexs = @specification[:exclude_methods].find_all {|s| s.kind_of? Regexp}
        return false if regexs.empty?
        regexs.find {|re| method.to_s =~ re}          
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
