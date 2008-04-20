require 'aquarium/extensions'
require 'aquarium/finders'
require 'aquarium/utils'
require 'aquarium/aspects/advice'
require 'aquarium/aspects/exclusion_handler'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'
require 'aquarium/aspects/default_objects_handler'

module Aquarium
  module Aspects
    
    # == Aspect
    # Aspects "advise" one or more method invocations for one or more types or objects
    # (including class methods on types). The corresponding advice is a Proc that is
    # invoked either before the join point, after it returns, after it raises an exception, 
    # after either event, or around the join point, meaning the advice runs and it decides 
    # when and if to invoke the advised method. (Hence, around advice can run code before 
    # and after the join point call and it can "veto" the actual join point call).
    #  
    # See also Aquarium::Aspects::DSL::AspectDsl for more information.
    class Aspect
      include Advice
      include ExclusionHandler
      include DefaultObjectsHandler
      include Aquarium::Aspects
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::HashUtils
      include Aquarium::Utils::HtmlEscaper
      include Aquarium::Utils::OptionsUtils
  
      attr_reader   :specification, :pointcuts, :advice
  
      ASPECT_CANONICAL_OPTIONS = {
        "advice"            => %w[action do_action use_advice advise_with invoke call],
        "pointcuts"         => %w[pointcut],
        "named_pointcuts"   => %w[named_pointcut],
        "exceptions"        => %w[exception],
        "ignore_no_matching_join_points" => %[ignore_no_jps]
      }
      ["pointcuts", "named_pointcuts"].each do |pc_option|
        add_prepositional_option_variants_for pc_option, ASPECT_CANONICAL_OPTIONS
        add_exclude_options_for               pc_option, ASPECT_CANONICAL_OPTIONS
      end
      CANONICAL_OPTIONS = Pointcut::CANONICAL_OPTIONS.merge ASPECT_CANONICAL_OPTIONS
         
      canonical_options_given_methods CANONICAL_OPTIONS


      # Aspect.new (:around | :before | :after | :after_returning | :after_raising ) \
      #   (:pointcuts => [...]), :named_pointcuts => [...] | \
      #    ((:types => [...] | :types_and_ancestors => [...] | :types_and_descendents => [...] \
      #     :objects => [...]), 
      #     :methods => [], :method_options => [...], \
      #     :attributes => [...], :attribute_options[...]), \
      #    (:advice = advice | do |join_point, obj, *args| ...; end)
      # 
      # where the parameters often have many synonyms (mostly to support a "humane
      # interface") and they are interpreted as followed:
      #
      # <tt>:around</tt>::
      #   Invoke the specified advice "around" the join points. It is up to the advice
      #   itself to call <tt>join_point.proceed</tt> (where <tt>join_point</tt> is the
      #   first option passed to the advice) if it wants the advised method to actually
      #   execute.
      #
      # <tt>:before</tt>::
      #   Invoke the specified advice before the join point.
      #
      # <tt>:after</tt>::
      #   Invoke the specified advice after the join point either returns successfully
      #   or raises an exception.
      #
      # <tt>:after_returning</tt>::
      #   Invoke the specified advice after the join point returns successfully.
      #
      # <tt>:after_raising [=> exception || [exception_list]]</tt>::
      # <tt>:after_raising, :exceptions => (exception || [exception_list])</tt>::
      # <tt>:after_raising, :exception  => (exception || [exception_list])</tt>::
      #   Invoke the specified advice after the join point raises one of the specified exceptions.
      #   If no exceptions are specified, the advice is invoked after any exception is raised. 
      #
      # <tt>:advice => proc</tt>::
      # <tt>:action => proc</tt>::
      # <tt>:do_action => proc</tt>::
      # <tt>:use_advice => proc</tt>::
      # <tt>:advise_with => proc</tt>::
      # <tt>:invoke => proc</tt>::
      # <tt>:call => proc</tt>::
      #   The specified advice to be invoked. Only one advice may be specified. If a block is
      #   specified, it is used instead.
      #
      # <tt>:pointcuts => pointcut || [pointcut_list]</tt>::
      # <tt>:pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:on_pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:on_pointcuts => pointcut || [pointcut_list]</tt>::
      # <tt>:in_pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:in_pointcuts => pointcut || [pointcut_list]</tt>::
      # <tt>:within_pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:within_pointcuts => pointcut || [pointcut_list]</tt>::
      #   One or an array of Pointcut or JoinPoint objects. Mutually-exclusive with the :types, :objects,
      #   :methods, :attributes, :method_options, and :attribute_options parameters.
      #
      # <tt>:named_pointcuts => {PointcutFinder options}</tt>::
      # <tt>:named_pointcut  => {PointcutFinder options}</tt>::
      # <tt>:on_named_pointcuts => {PointcutFinder options}</tt>::
      # <tt>:on_named_pointcut  => {PointcutFinder options}</tt>::
      # <tt>:in_named_pointcuts => {PointcutFinder options}</tt>::
      # <tt>:in_named_pointcut  => {PointcutFinder options}</tt>::
      # <tt>:within_named_pointcuts => {PointcutFinder options}</tt>::
      # <tt>:within_named_pointcut  => {PointcutFinder options}</tt>::
      #   Search for class constant and/or class variable "named" pointcuts, as specified using the options
      #   documented for PointcutFinder#find.
      #
      # <tt>:exclude_pointcuts => pointcut || [pointcut_list]</tt>::
      # <tt>:exclude_named_pointcuts => {PointcutFinder options}</tt>::
      #   Exclude the pointcuts. The "exclude_" prefix can be used with any of the :pointcuts and
      #   :named_pointcuts synonyms. 
      #
      # <tt>:ignore_no_matching_join_points => true | false</tt>
      # <tt>ignore_no_jps => true | false</tt>::
      #   Do not issue a warning if no join points are actually matched by the aspect. By default, the value
      #   is false, meaning that a WARN-level message will be written to the log. It is usually very helpful
      #   to be warned when no matches occurred, for diagnostic purposes!
      #
      # Aspect.new also accepts all the same options that Pointcut accepts, including the synonyms for :types,
      # :methods, etc. It also accepts the "universal" options documented in OptionsUtils.
      def initialize *options, &block
        @first_option_that_was_method = []
        opts = rationalize options
        init_specification opts, CANONICAL_OPTIONS, (Pointcut::ATTRIBUTE_OPTIONS_VALUES + KINDS_IN_PRIORITY_ORDER) do
          finish_specification_initialization &block
        end
        init_pointcuts
        validate_specification
        return if noop
        advise_join_points
      end
  
      def join_points_matched 
        get_jps :join_points_matched
      end
  
      def join_points_not_matched
        get_jps :join_points_not_matched
      end
      
      def unadvise
        return if noop
        @pointcuts.each do |pointcut|
          interesting_join_points(pointcut).each do |join_point|
            remove_advice_for_aspect_at join_point
          end
        end
      end

      alias :unadvise_join_points :unadvise
  
      def inspect
        "Aspect: {specification: #{specification.inspect}, pointcuts: #{pointcuts.inspect}, advice: #{advice.inspect}}"
      end
  
      alias :to_s :inspect
  
      # We have to ignore advice in the comparison. As recently discussed in ruby-users, there are very few situations.
      # where Proc#eql? returns true.
      def eql? other
        self.object_id == other.object_id ||
          (self.class.eql?(other.class) && specification == other.specification && pointcuts == other.pointcuts)
      end

      alias :== :eql?
  
      protected

      def rationalize options 
        return {} if options.nil? or options.empty?
        return options if options.size > 1
        # remove [] wrapping if we're wrapping a single hash element
        return (options.first.kind_of?(Hash) or options.first.kind_of?(Array)) ? options.first : options  
      end
      
      def finish_specification_initialization &block
        Advice.kinds.each do |kind|
          found, value_array = contains_advice_kind kind
          @specification[kind] = Set.new(value_array) if found
        end
        init_pointcut_specific_specification
        options_to_ignore_when_validating = []
        unless methods_given?
          options_to_ignore_when_validating = use_first_nonadvice_symbol_as_method
        end
        calculate_excluded_types
        @advice = determine_advice block
        # Be careful to only add the exceptions if :after_raising was actually specified! 
        if (exceptions_given? and specified_advice_kinds.include?(:after_raising))
          @specification[:after_raising] += exceptions_given
        end
        options_to_ignore_when_validating
      end
      
      def contains_advice_kind kind
        keys = @original_options
        hash = {}
        if Array === @original_options 
          if Hash === @original_options.last 
            hash = @original_options.last
            keys = @original_options[0...-1] + hash.keys
          end
        else Hash === @original_options
          hash = @original_options
          keys = @original_options.keys
        end
        keys.include?(kind) ? [true, make_array(hash[kind])] : [false, []]
      end
      
      def calculate_excluded_types
        type_finder_options = {}
        %w[types types_and_ancestors types_and_descendents].each do |opt|
          type_finder_options[opt.intern] = @specification["exclude_#{opt}".intern] if @specification["exclude_#{opt}".intern]
        end
        excluded_types = Aquarium::Finders::TypeFinder.new.find type_finder_options
        @specification[:exclude_types_calculated] = excluded_types.matched.keys
      end
      
      def determine_advice block
        # There can be only one advice; take any one in the set; options validation will raise if there is more than one.
        block || (@specification[:advice].to_a.first)
      end
      
      def init_pointcut_specific_specification
        options_hash = hash_in_original_options
        @specification.merge! Pointcut.make_attribute_reading_writing_options(options_hash)
        # Map the method options to their canonical values:
        @specification[:method_options] = Aquarium::Finders::MethodFinder.init_method_options(@specification[:method_options])

        Pointcut::validate_attribute_options @specification, options_hash
      end
      
      def hash_in_original_options
        @original_options.kind_of?(Array) ? @original_options.last : @original_options
      end
      
      def init_pointcuts
        set_calculated_excluded_pointcuts determine_excluded_pointcuts
        pointcuts  = determine_specified_pointcuts
        pointcuts += determine_named_pointcuts
        if pointcuts.empty?   # If no PCs specified, then the user must have specified :types, ...
          pc_options = {}
          Pointcut::CANONICAL_OPTIONS.keys.each do |pc_option|
            pco_sym = pc_option.intern
            pc_options[pco_sym] = @specification[pco_sym] unless @specification[pco_sym].nil?
          end
          pointcuts << Pointcut.new(pc_options)
        end
        @pointcuts = Set.new(remove_excluded_join_points_and_pointcuts(pointcuts))
        warn_if_no_join_points_matched
      end

      def determine_specified_pointcuts
        pointcuts_given.inject([]) do |pointcuts, pointcut|
          if pointcut.kind_of? Pointcut
            pointcuts << pointcut 
          elsif pointcut.kind_of? JoinPoint
            pointcuts << Pointcut.new(:join_point => pointcut) 
          else  # a hash of Pointcut.new options?
            pointcuts << Pointcut.new(pointcut) 
          end
          pointcuts
        end
      end
      
      def determine_named_pointcuts
        named_pointcuts_given.inject([]) do |pointcuts, pointcut_spec|
          found_pointcuts_results = Aquarium::Finders::PointcutFinder.new.find(pointcut_spec) 
          pointcuts += found_pointcuts_results.found_pointcuts
          pointcuts
        end
      end
      
      def determine_excluded_pointcuts
        exclude_named_pointcuts_given.inject([]) do |excluded_pointcuts, pointcut_spec|
          found_pointcuts_results = Aquarium::Finders::PointcutFinder.new.find(pointcut_spec) 
          excluded_pointcuts += found_pointcuts_results.found_pointcuts
        end
      end
      
      def warn_if_no_join_points_matched
        return unless should_warn_if_no_matching_join_points
        @pointcuts.each do |pc|
          if pc.join_points_matched.size > 0
            return
          end
        end
        msg  = "Warning: No join points were matched. The options specified were #{@original_options.inspect}."
        msg += " The resulting specification was #{@specification.inspect}." if logger.debug?
        logger.warn msg
      end
      
      def should_warn_if_no_matching_join_points
        @specification[:ignore_no_matching_join_points].nil? or 
        @specification[:ignore_no_matching_join_points].empty? or 
        @specification[:ignore_no_matching_join_points].to_a.first == false
      end
      
      def remove_excluded_join_points_and_pointcuts pointcuts
        pointcuts.reject do |pc|
          pc.join_points_matched.delete_if do |jp|
            join_point_excluded? jp
          end
          pc.empty?
        end
      end
      
      def advise_join_points
        advice = @advice.to_proc
        @pointcuts.each do |pointcut|
          interesting_join_points(pointcut).each do |join_point|
            add_advice_framework(join_point) if need_advice_framework?(join_point)
            Advice.sort_by_priority_order(specified_advice_kinds).reverse.each do |advice_kind|
              add_advice_to_chain join_point, advice_kind, advice
            end
          end
        end
      end
  
      def interesting_join_points pointcut
        pointcut.join_points_matched.reject do |join_point| 
          join_point_for_aspect_implementation_method? join_point
        end
      end

      def join_point_for_aspect_implementation_method? join_point
        join_point.method_name.to_s.index("#{Aspect.aspect_method_prefix}") == 0
      end
      
      def add_advice_to_chain join_point, advice_kind, advice
        start_of_advice_chain = Aspect.get_advice_chain join_point
        options = @specification.merge({
          :aspect => self,
          :advice_kind => advice_kind, 
          :advice => advice, 
          :next_node => start_of_advice_chain,
          :static_join_point => join_point})
        # New node is new start of chain.
        Aspect.set_advice_chain(join_point, AdviceChainNodeFactory.make_node(options))
      end

      def get_jps which_jps
        jps = Set.new
        @pointcuts.each do |pointcut|
          jps = jps.union(pointcut.send(which_jps))
        end
        jps
      end
  
      # Useful for debugging...
      def self.advice_chain_inspect advice_chain
        return "[nil]" if advice_chain.nil?
        "<br/>"+advice_chain.inspect do |ac|
          "#{ac.class.name}:#{ac.object_id}: join_point = #{ac.static_join_point}: aspect = #{ac.aspect.object_id}, next_node = #{advice_chain_inspect ac.next_node}"
        end.gsub(/\</,"&lt;").gsub(/\>/,"&gt;")+"<br/>"
      end

      def need_advice_framework? join_point
        alias_method_name = (Aspect.make_saved_method_name join_point).intern
        private_method_defined?(join_point, alias_method_name) == false
      end
      
      def add_advice_framework join_point
        alias_method_name = (Aspect.make_saved_method_name join_point).intern
        type_to_advise = Aspect.type_to_advise_for join_point
        # Note: Must set advice chain, a class variable on the type we're advising, FIRST. 
        # Otherwise the class_eval that follows will assume the @@ advice chain belongs to Aspect!
        Aspect.set_advice_chain join_point, AdviceChainNodeFactory.make_node(
          :aspect => nil,  # Belongs to all aspects that might advise this join point!
          :advice_kind => :none, 
          :alias_method_name => alias_method_name,
          :static_join_point => join_point)
        type_being_advised_text = join_point.instance_method? ? "self.class" : "self"
        unless Aspect.is_type_join_point?(join_point) 
          type_being_advised_text = "(class << self; self; end)"
        end
        type_to_advise2 = join_point.instance_method? ? type_to_advise : (class << type_to_advise; self; end)
        type_to_advise2.class_eval(<<-EOF, __FILE__, __LINE__)
          #{def_eigenclass_method_text join_point}
          #{alias_original_method_text alias_method_name, join_point, type_being_advised_text}
        EOF
      end
      
      # When advising an instance, create an override method that gets advised instead of the types method.
      # Otherwise, all objects will be advised!
      # Note: this also solves bug #15202.
      def def_eigenclass_method_text join_point
        Aspect.is_type_join_point?(join_point) ? "" : "def #{join_point.method_name} *args; super; end"
      end

      # For the temporary eigenclass method wrapper, alias it to a temporary name then undefine it, so it 
      # completely disappears. Next, remove_method on the method name so the object starts responding again
      # to the original definition.
      def undef_eigenclass_method_text join_point
        Aspect.is_type_join_point?(join_point) ? "" : "remove_method :#{join_point.method_name}"
      end

      def self.is_type_join_point? join_point
        Aquarium::Utils::TypeUtils.is_type? join_point.type_or_object
      end
      
      def self.type_to_advise_for join_point
        join_point.target_type ? join_point.target_type : (class << join_point.target_object; self; end)
      end

      def alias_original_method_text alias_method_name, join_point, type_being_advised_text
        target_self = join_point.instance_method? ? "self" : join_point.target_type.name
        advice_chain_attr_sym = Aspect.make_advice_chain_attr_sym join_point
        <<-EOF
        alias_method :#{alias_method_name}, :#{join_point.method_name}
        def #{join_point.method_name} *args, &block_for_method
          advice_chain = #{type_being_advised_text}.send :class_variable_get, "#{advice_chain_attr_sym}"
          static_join_point = advice_chain.static_join_point
          advice_join_point = static_join_point.make_current_context_join_point(
            :advice_kind => #{advice_kinds_given.inspect}, 
            :advised_object => #{target_self}, 
            :parameters => args, 
            :block_for_method => block_for_method)
          advice_chain.call advice_join_point, #{target_self}, *args
        end
        #{join_point.visibility.to_s} :#{join_point.method_name}
        private :#{alias_method_name}
        EOF
      end

      def unalias_original_method_text alias_method_name, join_point
        <<-EOF
        alias_method :#{join_point.method_name}, :#{alias_method_name}
        #{join_point.visibility.to_s} :#{join_point.method_name}
        undef_method :#{alias_method_name}
        EOF
      end
  
      def remove_advice_for_aspect_at join_point
        return unless Aspect.advice_chain_exists? join_point
        prune_nodes_in_advice_chain_for join_point
        advice_chain = Aspect.get_advice_chain join_point
        remove_advice_framework_for(join_point) if advice_chain.empty?
      end

      def prune_nodes_in_advice_chain_for join_point
        advice_chain = Aspect.get_advice_chain join_point
        # Use equal? for the aspects to compare object id only,
        while advice_chain.empty? == false && advice_chain.aspect.equal?(self)
          advice_chain = advice_chain.next_node 
        end
        node = advice_chain
        while node.empty? == false
          while node.next_node.aspect.equal?(self)
            node.next_node = node.next_node.next_node
          end
          node = node.next_node 
        end
        Aspect.set_advice_chain join_point, advice_chain
      end
  
      def remove_advice_framework_for join_point
        type_to_advise = Aspect.type_to_advise_for join_point
        type_to_advise.class_eval(<<-EVAL_WRAPPER, __FILE__, __LINE__)
          #{restore_original_method_text join_point}
        EVAL_WRAPPER
        Aspect.remove_advice_chain join_point
      end
  
      def restore_original_method_text join_point
        alias_method_name = (Aspect.make_saved_method_name join_point).intern
        <<-EOF
          #{join_point.instance_method? ? "" : "class << self"}
          #{unalias_original_method_text alias_method_name, join_point}
          #{undef_eigenclass_method_text join_point}
          #{join_point.instance_method? ? "" : "end"}
        EOF
      end
      
      # TODO optimize calls to these *_advice_chain methods from other private methods.
      def self.advice_chain_exists? join_point
        advice_chain_attr_sym = self.make_advice_chain_attr_sym join_point
        type_to_advise_for(join_point).class_variable_defined? advice_chain_attr_sym
      end

      def self.set_advice_chain join_point, advice_chain
        advice_chain_attr_sym = self.make_advice_chain_attr_sym join_point
        type_to_advise_for(join_point).send :class_variable_set, advice_chain_attr_sym, advice_chain
      end

      def self.get_advice_chain join_point
        advice_chain_attr_sym = self.make_advice_chain_attr_sym join_point
        type_to_advise_for(join_point).send :class_variable_get, advice_chain_attr_sym
      end
    
      def self.remove_advice_chain join_point
        advice_chain_attr_sym = self.make_advice_chain_attr_sym join_point
        type_to_advise_for(join_point).send :remove_class_variable, advice_chain_attr_sym
      end

      def private_method_defined? join_point, alias_method_name
        type_to_advise = Aspect.type_to_advise_for join_point
        type_to_advise.send(:private_instance_methods).include? alias_method_name.to_s
      end
  
      def self.make_advice_chain_attr_sym join_point
        class_or_object_prefix = is_type_join_point?(join_point) ? "class_" : ""
        type_or_object_key = make_type_or_object_key join_point
        valid_name = Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name join_point.method_name
        "@@#{Aspect.aspect_method_prefix}#{class_or_object_prefix}advice_chain_#{type_or_object_key}_#{valid_name}".intern
      end
      
      def self.make_saved_method_name join_point
        type_or_object_key = make_type_or_object_key join_point
        valid_name = Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name join_point.method_name
        "#{Aspect.aspect_method_prefix}saved_#{type_or_object_key}_#{valid_name}"
      end
  
      def self.aspect_method_prefix
        "_aspect_"
      end
  
      def some_type_object_join_point_or_pc_option_given?
        pointcuts_given? or named_pointcuts_given? or join_points_given? or some_type_option_given? or objects_given? 
      end
      
      def some_type_option_given?
        types_given? or types_and_ancestors_given? or types_and_descendents_given? 
      end
      
      def self.determine_type_or_object join_point
        join_point.type_or_object
      end
      
      def self.make_type_or_object_key join_point
        Aquarium::Utils::NameUtils.make_type_or_object_key determine_type_or_object(join_point)
      end
      
      def specified_advice_kinds
        Advice.kinds & @specification.keys
      end
  
      def options_given? option1, option2
        @specification[option1] and @specification[option2]
      end
      
      def validate_specification 
        bad_options("One of #{Advice.kinds.inspect} is required.") unless advice_kinds_given?
        %w[before after after_returning after_raising].each do |advice_kind|
          bad_options(":around can't be used with :#{advice_kind}.") if options_given? :around, advice_kind.intern
        end
        %w[after_returning after_raising].each do |advice_kind|
          bad_options(":after can't be used with :#{advice_kind}.") if options_given? :after, advice_kind.intern
        end
        bad_options(":after_returning can't be used with :after_raising.") if options_given? :after_returning, :after_raising
        bad_options(":exceptions can't be specified except with :after_raising.") if exceptions_given? and not specified_advice_kinds.include?(:after_raising)
        unless some_type_object_join_point_or_pc_option_given? or default_objects_given?
          bad_options("At least one of :pointcut(s), :named_pointcut(s), :join_point(s), :type(s), :type(s)_and_ancestors, :type(s)_and_descendents, or :object(s) is required.") 
        end
        if (pointcuts_given? or named_pointcuts_given?) and (some_type_option_given? or objects_given?)
          bad_options("Can't specify both :pointcut(s) or :named_pointcut(s) and one or more of :type(s), and/or :object(s).") 
        end
        unless noop
          if (not @specification[:advice].nil?) && @specification[:advice].size > 1
            bad_options "You can only specify one advice object for the :advice option."
          end
          if @advice.nil?
            bad_options "No advice block nor :advice option was given."
          elsif @advice.arity == -2
            bad_options "It appears that your advice parameter list is the obsolete format |jp, *args|. The correct format is |jp, object, *args|"
          end
        end
      end

      def advice_kinds_given
        Advice.kinds.inject([]) {|ary, kind| ary << kind if @specification[kind]; ary}
      end

      def advice_kinds_given?
        not advice_kinds_given.empty?
      end

      def use_first_nonadvice_symbol_as_method 
        2.times do |i|
          if @original_options.size >= i+1
            sym = @original_options[i]
            if sym.kind_of?(Symbol) && !Advice::kinds.include?(sym)
              @specification[:methods] = Set.new([sym])
              @specification.delete sym
              @first_option_that_was_method << sym
              return [sym]
            end
          end
        end
        []
      end
      
      def bad_options message
        raise Aquarium::Utils::InvalidOptions.new("Invalid options given. " + message + 
        " (options: #{@original_options.inspect}, mapped to specification: #{@specification.inspect})")
      end
    end
  end
end
