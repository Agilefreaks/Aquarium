require 'set'
require File.dirname(__FILE__) + '/../utils/array_utils'
require File.dirname(__FILE__) + '/../utils/invalid_options'
require File.dirname(__FILE__) + '/../utils/set_utils'
require File.dirname(__FILE__) + '/../utils/type_utils'
require File.dirname(__FILE__) + '/../utils/options_utils'
require File.dirname(__FILE__) + '/finder_result'

# Find methods and types and objects.
module Aquarium
  module Finders
    class MethodFinder
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::OptionsUtils
  
      # Returns a Aquarium::Finders::FinderResult for the hash of types, type names, and/or regular expressions
      # and the corresponding method name <b>symbols</b> found.
      # Method names, not method objects, are always returned, because we can only get
      # method objects for instance methods if we have an instance!
      #
      # finder_result = MethodFinder.new.find :types => ... {, :methods => ..., :method_options => [...]}
      # where
      # "{}" indicate optional arguments
      #
      # <tt>:types => types_and_type_names_and_regexps</tt>::
      # <tt>:type  => types_and_type_names_and_regexps</tt>::
      # <tt>:for_types => types_and_type_names_and_regexps</tt>::
      # <tt>:for_type  => types_and_type_names_and_regexps</tt>::
      # <tt>:on_types => types_and_type_names_and_regexps</tt>::
      # <tt>:on_type  => types_and_type_names_and_regexps</tt>::
      # <tt>:in_types => types_and_type_names_and_regexps</tt>::
      # <tt>:in_type  => types_and_type_names_and_regexps</tt>::
      # <tt>:within_types => types_and_type_names_and_regexps</tt>::
      # <tt>:within_type  => types_and_type_names_and_regexps</tt>::
      #   One or more types, type names and/or regular expessions to match. 
      #   Specify one or an array of values.
      #
      # <tt>:objects => objects</tt>::
      # <tt>:object  => objects</tt>::
      # <tt>:for_objects => objects</tt>::
      # <tt>:for_object  => objects</tt>::
      # <tt>:on_objects => objects</tt>::
      # <tt>:on_object  => objects</tt>::
      # <tt>:in_objects => objects</tt>::
      # <tt>:in_object  => objects</tt>::
      # <tt>:within_objects => objects</tt>::
      # <tt>:within_object  => objects</tt>::
      #   One or more objects to match. 
      #   Specify one or an array of values.
      #   Note: Currently, string or symbol objects will be misinterpreted as type names!
      #
      # <tt>:methods => method_names_and_regexps</tt>::
      # <tt>:method  => method_names_and_regexps</tt>::
      # <tt>:within_methods => method_names_and_regexps</tt>::
      # <tt>:within_method  => method_names_and_regexps</tt>::
      # <tt>:calling   => method_names_and_regexps</tt>::
      # <tt>:invoking  => method_names_and_regexps</tt>::
      # <tt>:calls_to  => method_names_and_regexps</tt>::
      # <tt>:sending_message_to  => method_names_and_regexps</tt>::
      # <tt>:sending_messages_to => method_names_and_regexps</tt>::
      #   One or more method names and regular expressions to match.
      #   Specify one or an array of values. If :all or :all_methods is specified, all
      #   methods will be matched. That is, these special values are equivalent to the
      #   the regular expression /.+/. 
      #
      # <tt>:exclude_methods => method_names_and_regexps</tt>::
      # <tt>:exclude_method  => method_names_and_regexps</tt>::
      # <tt>:exclude_&lt;other_method_synonyms&gt; => method_names_and_regexps</tt>::
      #   One or more method names and regular expressions to exclude from the match.
      #   Specify one or an array of values.
      #
      # <tt>:method_options => options</tt>::
      # <tt>:method_option => options</tt>::
      # <tt>:options  => options</tt>::
      # <tt>:restricting_methods_to => options</tt>::
      #   By default, searches for public instance methods. Specify one or more
      #   of the following options for alternatives. You can combine any of the
      #   <tt>:public</tt>, <tt>:protected</tt>, and <tt>:private</tt>, as well as
      #   <tt>:instance</tt> and <tt>:class</tt>.
      #     
      # <tt>:public</tt> or <tt>:public_methods</tt>::    Search for public methods (default).
      # <tt>:private</tt> or <tt>:private_methods</tt>::   Search for private methods. 
      # <tt>:protected</tt> or <tt>:protected_methods</tt>:: Search for protected methods.
      # <tt>:instance</tt> or <tt>:instance_methods</tt>::  Search for instance methods.
      # <tt>:class</tt> or <tt>:class_methods</tt>::     Search for class methods.
      # <tt>:singleton</tt> or <tt>:singleton_methods</tt>:: Search for singleton methods. (Using :class for objects 
      # won't work and :class, :public, :protected, and :private are ignored when 
      # looking for singleton methods.)
      # <tt>:exclude_ancestor_methods</tt>:: Suppress "ancestor" methods. This
      # means that if you search for a override method +foo+ in a
      # +Derived+ class that is defined in the +Base+ class, you won't find it!
      #
      def find options = {}
        init_specification options, CANONICAL_OPTIONS do
          finish_specification_initialization 
        end
        return Aquarium::Finders::FinderResult.new if nothing_to_find?
        types_and_objects = input_types + input_objects
        method_names_or_regexps = input_methods
        if method_names_or_regexps.empty?
          not_matched = {}
          types_and_objects.each {|t| not_matched[t] = []}
          return Aquarium::Finders::FinderResult.new(:not_matched => not_matched)
        end
        result = do_find_all_by types_and_objects, method_names_or_regexps
        unless (input_exclude_methods.nil? or input_exclude_methods.empty?)
          result -= do_find_all_by types_and_objects, input_exclude_methods
        end
        result
      end
  
      NIL_OBJECT = MethodFinder.new unless const_defined?(:NIL_OBJECT)

      # TODO remove (or deprecate) the "options" option!
      METHOD_FINDER_CANONICAL_OPTIONS = {
        "objects" => %w[object for_object for_objects on_object on_objects in_object in_objects within_object within_objects],
        "methods" => %w[method within_method within_methods calling invoking invocations_of calls_to sending_message_to sending_messages_to],
        "method_options" => %w[options method_option restricting_methods_to] 
      }
      
      %w[objects methods].each do |key|
        METHOD_FINDER_CANONICAL_OPTIONS["exclude_#{key}"] = METHOD_FINDER_CANONICAL_OPTIONS[key].map {|x| "exclude_#{x}"}
      end
      METHOD_FINDER_CANONICAL_OPTIONS["methods"].dup.each do |synonym|
        if synonym =~ /methods?$/
          METHOD_FINDER_CANONICAL_OPTIONS["methods"] << "#{synonym}_matching"
        else
          METHOD_FINDER_CANONICAL_OPTIONS["methods"] << "#{synonym}_methods_matching"
        end
      end
      
      CANONICAL_OPTIONS = METHOD_FINDER_CANONICAL_OPTIONS.merge(Aquarium::Finders::TypeFinder::TYPE_FINDER_CANONICAL_OPTIONS)

      RECOGNIZED_METHOD_OPTIONS = {
        "all"       => %w[all_methods],
        "public"    => %w[public_methods],
        "private"   => %w[private_methods],
        "protected" => %w[protected_methods],
        "instance"  => %w[instance_methods],
        "class"     => %w[class_methods],
        "singleton" => %w[singleton_methods],
        "exclude_ancestor_methods" => %w[exclude_ancestors exclude_ancestors_methods suppress_ancestors suppress_ancestor_methods suppress_ancestors_methods]
      }
        
      def self.init_method_options scope_options_set
        return Set.new([]) if scope_options_set.nil?
        options = []
        scope_options_set.each do |opt|
          if RECOGNIZED_METHOD_OPTIONS.keys.include?(opt.to_s)
            options << opt
          else
            RECOGNIZED_METHOD_OPTIONS.keys.each do |key|
              options << key.intern if RECOGNIZED_METHOD_OPTIONS[key].include?(opt.to_s)
            end
          end
        end
        options << :instance unless (options.include?(:class) or options.include?(:singleton))
        Set.new(options.sort.uniq)
      end
  
      def self.all_recognized_method_option_symbols
        all = RECOGNIZED_METHOD_OPTIONS.keys.map {|key| key.intern}
        RECOGNIZED_METHOD_OPTIONS.keys.inject(all) do |all, key|
          all += RECOGNIZED_METHOD_OPTIONS[key].map {|value| value.intern}
          all
        end
      end
      
      def self.is_recognized_method_option string_or_symbol
        sym = string_or_symbol.respond_to?(:intern) ? string_or_symbol.intern : string_or_symbol
        all_recognized_method_option_symbols.include? sym
      end
  
      protected
  
      def do_find_all_by types_and_objects, method_names_or_regexps
        types_and_objects = make_array types_and_objects
        names_or_regexps  = make_methods_array method_names_or_regexps
        types_and_objects_to_matched_methods = {}
        types_and_objects_not_matched = {}
        types_and_objects.each do |type_or_object|
          reflection_method_names = make_methods_reflection_method_names type_or_object, "methods"
          found_methods = Set.new
          names_or_regexps.each do |name_or_regexp|
            method_array = []
            reflection_method_names.each do |reflect|
              method_array += reflect_methods(type_or_object, reflect).grep(make_regexp(name_or_regexp))
            end
            if exclude_ancestor_methods?
              method_array = remove_ancestor_methods type_or_object, reflection_method_names, method_array
            end
            found_methods += method_array
          end
          if found_methods.empty?
            types_and_objects_not_matched[type_or_object] = method_names_or_regexps
          else
            types_and_objects_to_matched_methods[type_or_object] = found_methods.to_a.sort.map {|m| m.intern}
          end
        end
        Aquarium::Finders::FinderResult.new types_and_objects_to_matched_methods.merge(:not_matched => types_and_objects_not_matched)
      end
  
      def finish_specification_initialization
        @specification[:method_options] = MethodFinder.init_method_options(@specification[:method_options]) if @specification[:method_options]
        extra_validation
      end
      
      def nothing_to_find? 
        types_and_objects = input_types + input_objects
        types_and_objects.nil? or types_and_objects.empty? or all_exclude_all_methods?
      end
      
      def input_types
        @specification[:types]
      end
  
      def input_objects
        @specification[:objects]
      end
  
      def input_methods
        @specification[:methods]
      end
  
      def input_exclude_methods
        @specification[:exclude_methods]
      end
  
      def all_exclude_all_methods?
        input_exclude_methods.include?(:all) or input_exclude_methods.include?(:all_methods)
      end
  
      def exclude_ancestor_methods?
        @specification[:method_options].include?(:exclude_ancestor_methods)
      end
      
      private
  
      def make_methods_array *array_or_single_item
        ary = make_array(*array_or_single_item).reject {|m| m.to_s.strip.empty?}
        ary = [/^.+$/] if include_all_methods?(ary) 
        ary
      end
      
      def include_all_methods? array
        array.include?(:all) or array.include?(:all_methods)
      end
  
      def make_regexp name_or_regexp
        name_or_regexp.kind_of?(Regexp) ? name_or_regexp : /^#{Regexp.escape(name_or_regexp.to_s)}$/
      end
  
      def remove_ancestor_methods type_or_object, reflection_method_names, method_array
        type = type_or_object
        unless (Aquarium::Utils::TypeUtils.is_type? type_or_object) 
          type = type_or_object.class
          # Must recalc reflect methods if we've switched to the type of the input object.
          reflection_method_names = make_methods_reflection_method_names type, "methods"
        end
        ancestors = type.ancestors + type.included_modules
        return method_array if ancestors.nil? || ancestors.size <= 1 # 1 for type_or_object itself!
        ancestors.each do |ancestor|
          unless ancestor.name == type.to_s
            reflection_method_names.each do |reflect|
              method_array -= ancestor.method(reflect).call
            end
          end
        end
        method_array
      end
  
      def make_methods_reflection_method_names type_or_object, root_method_name
        is_type = Aquarium::Utils::TypeUtils.is_type?(type_or_object)
        scope_prefixes = []
        class_instance_prefixes = []
        @specification[:method_options].each do |opt, value|
          opt_string = opt.to_s
          case opt_string
          when "public", "private", "protected" 
            scope_prefixes += [opt_string + "_"]
          when "instance"
            class_instance_prefixes += is_type ? [opt_string + "_"] : [""]
          when "class"
            # We want to use the "bare" (public|private)_<root_method_name> calls 
            # to get class methods, because we will invoke these methods on class objects!
            # For instances, class methods aren't supported.
            class_instance_prefixes += [""] if is_type
          when "singleton"
            class_instance_prefixes += [opt_string + "_"]
          else 
            true # do nothing; "true" is here to make rcov happy.
          end
        end
        scope_prefixes = ["public_"] if scope_prefixes.empty?
        class_instance_prefixes = [""] if (class_instance_prefixes.empty? and is_type)
        results = []
        scope_prefixes.each do |scope_prefix|
          class_instance_prefixes.each do |class_instance_prefix|
            prefix  = class_instance_prefix.eql?("singleton_") ? class_instance_prefix : scope_prefix + class_instance_prefix
            results += [(prefix + root_method_name).intern]
          end
        end
        results
      end
  
      def reflect_methods object, reflect_method
        if object.kind_of?(String) or object.kind_of?(Symbol)
          eval "#{object.to_s}.#{reflect_method}"
        else
          return [] unless object.respond_to? reflect_method
          method = object.method reflect_method
          method.call object
        end
      end
  
      def extra_validation 
        method_options = @specification[:method_options]
        return if method_options.nil?
        if method_options.include?(:singleton) && 
          (method_options.include?(:class) || method_options.include?(:public) ||
           method_options.include?(:protected) || method_options.include?(:private))
          raise Aquarium::Utils::InvalidOptions.new("The :class:, :public, :protected, and :private flags can't be used with the :singleton flag.")
        end
      end
    end
  end
end

