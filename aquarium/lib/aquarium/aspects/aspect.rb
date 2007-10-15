require 'aquarium/extensions'
require 'aquarium/utils'
require 'aquarium/aspects/advice'
require 'aquarium/aspects/join_point'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'
require 'aquarium/aspects/default_object_handler'

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
      include DefaultObjectHandler
      include Aquarium::Utils::ArrayUtils
      include Aquarium::Utils::HashUtils
      include Aquarium::Utils::HtmlEscaper
  
      attr_accessor :verbose, :log
      attr_reader   :specification, :pointcuts, :advice
  
      # Aspect.new (:around | :before | :after | :after_returning | :after_raising ) \
      #   (:pointcuts => [...]), | \
      #    ((:types => [...] | :objects => [...]), 
      #     :methods => [], :method_options => [...], \
      #     :attributes => [...], :attribute_options[...]), \
      #    (:advice = advice | do |join_point, *args| ...; end)
      # 
      # where the parameters often have many synonyms (mostly to support a "humane
      # interface") and they are interpreted as followed:
      #
      # <tt>:around</tt>::
      #   Invoke the specified advice "around" the join points. It is up to the advice
      #   itself to call <tt>join_point.proceed</tt> (where <tt>join_point</tt> is the
      #   first argument passed to the advice) if it wants the advised method to actually
      #   execute.
      #
      # <tt>:before</tt>::
      #   Invoke the specified advice as before the join point.
      #
      # <tt>:after</tt>::
      #   Invoke the specified advice as after the join point either returns successfully
      #   or raises an exception.
      #
      # <tt>:after_returning</tt>::
      #   Invoke the specified advice as after the join point returns successfully.
      #
      # <tt>:after_raising</tt>::
      #   Invoke the specified advice as after the join point raises an exception.
      #
      # <tt>:pointcuts => pointcut || [pointcut_list]</tt>::
      # <tt>:pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:within_pointcut  => pointcut || [pointcut_list]</tt>::
      # <tt>:within_pointcuts => pointcut || [pointcut_list]</tt>::
      #   One or an array of Pointcut or JoinPoint objects. Mutually-exclusive with the :types, :objects,
      #   :methods, :attributes, :method_options, and :attribute_options parameters.
      #
      # <tt>:types => type || [type_list]</tt>::
      # <tt>:type  => type || [type_list]</tt>::
      # <tt>:within_type  => type || [type_list]</tt>::
      # <tt>:within_types => type || [type_list]</tt>::
      #   One or an array of types, type names and/or type regular expessions to advise. 
      #   All the :types, :objects, :methods, :attributes, :method_options, and :attribute_options
      #   are used to construct Pointcuts internally.
      #
      # <tt>:objects => object || [object_list]</tt>::
      # <tt>:object  => object || [object_list]</tt>::
      # <tt>:within_object  => object || [object_list]</tt>::
      # <tt>:within_objects => object || [object_list]</tt>::
      #   One or an array of objects to advise. 
      #
      # <tt>:default_object => object</tt>::
      #   An "internal" flag used by the methods that AspectDSL adds to Object. When no object
      #   or type is specified, the value of :default_object will be used, if defined. The
      #   AspectDSL methods set the value to self, so that the user doesn't have to in the 
      #   appropriate contexts. This flag is subject to change, so don't use it explicitly!
      #
      # <tt>:methods => method || [method_list]</tt>::
      # <tt>:method  => method || [method_list]</tt>::
      # <tt>:within_method  => method || [method_list]</tt>::
      # <tt>:within_methods => method || [method_list]</tt>::
      #   One or an array of methods, method names and/or method regular expessions to match. 
      #   By default, unless :attributes are specified, searches for public instance methods
      #   with the method option :exclude_ancestor_methods implied, unless explicit method 
      #   options are given.
      #
      # <tt>:method_options => [options]</tt>::
      #   One or more options supported by Aquarium::Finders::MethodFinder. Defaults to :exclude_ancestor_methods
      #
      # <tt>:attributes => attribute || [attribute_list]</tt>::
      # <tt>:attribute  => attribute || [attribute_list]</tt>::
      # <tt>:within_attribute  => attribute || [attribute_list]</tt>::
      # <tt>:within_attributes => attribute || [attribute_list]</tt>::
      #   One or an array of attribute names and/or regular expessions to match. 
      #   This is syntactic sugar for the corresponding attribute readers and/or writers
      #   methods, as specified using the <tt>:attrbute_options. Any matches will be
      #   joined with the matched :methods.</tt>.
      #
      # <tt>:attribute_options => [options]</tt>::
      #   One or more of <tt>:readers</tt>, <tt>:reader</tt> (synonymous), 
      #   <tt>:writers</tt>, and/or <tt>:writer</tt> (synonymous). By default, both
      #   readers and writers are matched.
      def initialize *options, &block
        process_input options, &block
        init_pointcuts
        return if specification[:noop]
        advise_join_points
      end
  
      def join_points_matched
        matched_jps = Set.new
        @pointcuts.each do |pointcut|
          matched_jps = matched_jps.union pointcut.join_points_matched
        end
        matched_jps
      end
  
      def unadvise
        return if @specification[:noop]
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

      def process_input options, &block
        @original_options = options
        make_specification options, &block
        @verbose = @specification[:verbose] || false
        @log     = @specification[:log] || ""
        validate_specification
      end  
  
      def make_specification options, &block
        opts = options.flatten.dup
        rationalize_parameters opts
        @specification = Aquarium::Utils::MethodUtils.method_args_to_hash(*opts) {|option| ""} # set other hash values to an empty string
        use_default_object_if_defined unless (types_given? || objects_given? || pointcuts_given?)
        use_first_nonadvice_symbol_as_method(opts) unless methods_given?
        @advice = block || @specification[:advice]
        if @advice.nil? && @specification[:noop].nil?
          raise Aquarium::Utils::InvalidOptions.new("No advice block or argument specified.") 
        end
      end

      def init_pointcuts
        pointcuts = []
        if pointcuts_given?
          pointcuts_given.each do |pointcut|
            if pointcut.kind_of?(Aquarium::Aspects::Pointcut)
              pointcuts << pointcut 
            elsif pointcut.kind_of?(Aquarium::Aspects::JoinPoint)
              pointcuts << Aquarium::Aspects::Pointcut.new(:join_point => pointcut) 
            else
              pointcuts << Aquarium::Aspects::Pointcut.new(pointcut) 
            end
          end
        else
          pc_options = {}
          pc_options[:types]   = types_given.to_a   if types_given?
          pc_options[:objects] = objects_given.to_a if objects_given?
          pc_options[:methods] = methods_given.to_a if methods_given?
          pc_options[:method_options] = method_options_given.to_a if method_options_given?
          pointcuts << Aquarium::Aspects::Pointcut.new(pc_options)
        end
        @pointcuts = Set.new(pointcuts)
      end

      def advise_join_points
        advice = @advice.to_proc
        @pointcuts.each do |pointcut|
          interesting_join_points(pointcut).each do |join_point|
            add_advice_framework join_point
            Aquarium::Aspects::Advice.sort_by_priority_order(specified_advice_kinds).reverse.each do |advice_kind|
              advice_chain = Aspect.get_advice_chain join_point.type_or_object, join_point.method_name
              add_advice_to_chain join_point, advice_chain, advice_kind, advice
            end
          end
        end
      end
  
      # Ignore any inserted methods that are part of the aspect implementation,
      # i.e., those that match the prefix returned by Aspect.aspect_method_prefix.
      def interesting_join_points pointcut
        pointcut.join_points_matched.reject do |join_point| 
          join_point.method_name.to_s =~ /^#{Aspect.aspect_method_prefix}/
        end
      end

      def add_advice_to_chain join_point, advice_chain, advice_kind, advice
        options = @specification.merge({
          :aspect => self,
          :advice_kind => advice_kind, 
          :advice => advice, 
          :next_node => advice_chain,
          :static_join_point => join_point})
        # The returned node becomes the lead node in the chain.
        advice_chain = Aspect.get_advice_chain join_point.type_or_object, join_point.method_name
        Aspect.set_advice_chain(join_point.type_or_object, join_point.method_name, Aquarium::Aspects::AdviceChainNodeFactory.make_node(options))
        advice_chain = Aspect.get_advice_chain join_point.type_or_object, join_point.method_name
      end

      # Useful for debugging...
      def self.advice_chain_inspect advice_chain
        return "[nil]" if advice_chain.nil?
        "<br/>"+advice_chain.inspect do |advice_chain|
          "#{advice_chain.class.name}:#{advice_chain.object_id}: aspect = #{advice_chain.aspect.object_id}, next_node = #{advice_chain_inspect advice_chain.next_node}"
        end.gsub(/\</,"&lt;").gsub(/\>/,"&gt;")+"<br/>"
      end
  
      def add_advice_framework join_point
        type_to_advise = join_point.target_type || (class << join_point.target_object; self; end)
        alias_method_name = (saved_method_name join_point).intern
        return if private_method_defined? join_point.type_or_object, alias_method_name
        type_to_advise.class_eval(<<-EVAL_WRAPPER, __FILE__, __LINE__)
          #{static_method_prefix join_point.instance_method?}
          #{alias_original_method_text alias_method_name, join_point}
          #{static_method_suffix join_point.instance_method?}
        EVAL_WRAPPER
        Aspect.set_advice_chain join_point.type_or_object, join_point.method_name, Aquarium::Aspects::AdviceChainNodeFactory.make_node(
          :aspect => nil,  # Belongs to all aspects that might advise this join point!
          :advice_kind => :none, 
          :alias_method_name => alias_method_name,
          :static_join_point => join_point)
          advice_chain = Aspect.get_advice_chain join_point.type_or_object, join_point.method_name
      end
      
      def static_method_prefix instance_method
        return "" if instance_method
        <<-EOF
          class << self
        EOF
      end

      def static_method_suffix instance_method
        return "" if instance_method
        <<-EOF
          end
        EOF
      end
  
      # Note that we make the alias for the original method private, so it doesn't pollute the "interface" 
      # of the advised classes. This also means that we have to use the Class.method(name).call()
      # idiom when invoking it.
      def alias_original_method_text alias_method_name, join_point
        self_name = join_point.target_type.nil? ? "self" : join_point.target_type.name
        target_self = join_point.instance_method? ? "self" : join_point.target_type.name
        <<-EOF
        alias_method :#{alias_method_name}, :#{join_point.method_name}
        def #{join_point.method_name} *args, &block_for_method
          advice_chain = Aspect.get_advice_chain #{self_name}, :#{join_point.method_name}
          static_join_point = advice_chain.static_join_point
          advice_join_point = Aspect.make_advice_join_point static_join_point, #{target_self}, args, block_for_method
          advice_chain.call advice_join_point, *args
        end
        #{join_point.visibility.to_s} :#{join_point.method_name}
        private :#{alias_method_name}
        EOF
      end
      
      def unalias_original_method_text alias_method_name, join_point
        self_name = join_point.target_type.nil? ? "self" : join_point.target_type.name
        <<-EOF
        alias_method :#{join_point.method_name}, :#{alias_method_name}
        #{join_point.visibility.to_s} :#{join_point.method_name}
        undef_method :#{alias_method_name}
        EOF
      end
  
      def remove_advice_chain_class_variable_text alias_method_name, join_point
        self_name = join_point.target_type.nil? ? "self" : join_point.target_type.name
        <<-EOF
        advice_chain_name = :@@#{Aspect.advice_chain_attr_name join_point.type_or_object, join_point.method_name}
        remove_class_variable advice_chain_name
        EOF
      end
  
      def self.make_advice_join_point static_join_point, object, method_parameters, block_for_method
        static_join_point.make_current_context_join_point(
          :advice_kind => :before, 
          :advised_object => object, 
          :parameters => method_parameters, 
          :block_for_method => block_for_method)
      end
  
      def remove_advice_for_aspect_at join_point
        advice_chain = Aspect.get_advice_chain join_point.type_or_object, join_point.method_name
        advice_chain = prune_nodes_in advice_chain
        if advice_chain.empty?
          remove_advice_framework_for join_point
        else
          Aspect.set_advice_chain join_point.type_or_object, join_point.method_name, advice_chain
        end
      end

      def prune_nodes_in advice_chain
        # Use equal? for the aspects to compare object id only,
        while advice_chain.empty? == false && advice_chain.aspect.equal?(self)
          advice_chain = advice_chain.next_node 
        end
        keeper_node = node = advice_chain
        while node.empty? == false
          while node.next_node.aspect.equal?(self)
            node.next_node = node.next_node.next_node
          end
          node = node.next_node 
        end
        advice_chain
      end
  
      def remove_advice_framework_for join_point
        if Aquarium::Utils::TypeUtils.is_type?(join_point.type_or_object)
          restore_type_method   join_point
        else
          restore_object_method join_point
        end
      end
  
      def restore_type_method join_point
        alias_method_name = (saved_method_name join_point).intern
        join_point.target_type.class_eval(<<-EVAL_WRAPPER, __FILE__, __LINE__)
          #{static_method_prefix join_point.instance_method?}
          #{unalias_original_method_text alias_method_name, join_point}
          #{static_method_suffix join_point.instance_method?}
          #{remove_advice_chain_class_variable_text alias_method_name, join_point}
        EVAL_WRAPPER
      end
      
      def restore_object_method join_point
        saved = saved_method_name join_point
        singleton = class << join_point.target_object; self; end
        singleton.class_eval do
          alias_method join_point.method_name, saved
          send join_point.visibility, join_point.method_name
          undef_method saved.intern
        end
        advice_chain_name = "@#{Aspect.advice_chain_attr_name join_point.type_or_object, join_point.method_name}".intern
        join_point.target_object.method(:remove_instance_variable).call advice_chain_name
      end

      def self.set_advice_chain type_or_object, method_name, advice_chain
        advice_chain_attr_sym = self.make_advice_chain_attr_sym type_or_object, method_name
        if Aquarium::Utils::TypeUtils.is_type?(type_or_object)
          type_or_object.class_eval do
            class_variable_set advice_chain_attr_sym, advice_chain
          end
        else
          type_or_object.instance_eval do
            instance_variable_set advice_chain_attr_sym, advice_chain
          end
        end
      end
  
      def self.get_advice_chain type_or_object, method_name
        advice_chain_attr_sym = self.make_advice_chain_attr_sym type_or_object, method_name
        if Aquarium::Utils::TypeUtils.is_type?(type_or_object) 
          type_or_object.class_eval do
            class_variable_get advice_chain_attr_sym
          end
        else
          type_or_object.instance_eval do
            instance_variable_get advice_chain_attr_sym
          end
        end
      end
  
      def self.make_advice_chain_attr_sym type_or_object, method_name
        ats = Aquarium::Utils::TypeUtils.is_type?(type_or_object) ? "@@" : "@"
        chain_class_var = (ats + self.advice_chain_attr_name(type_or_object, method_name)).intern
      end
      
    
      def private_method_defined? type_or_object, method_name
        if Aquarium::Utils::TypeUtils.is_type? type_or_object
          type_or_object.private_instance_methods.include? method_name.to_s
        else
          type_or_object.private_methods.include? method_name.to_s
        end
      end
  
      def self.advice_chain_attr_name type_or_object, method_name
        type_or_object_key = Aquarium::Utils::NameUtils.make_type_or_object_key(type_or_object)
        class_or_object_prefix = Aquarium::Utils::TypeUtils.is_type?(type_or_object) ? "class_" : ""
        valid_name = Aquarium::Utils::NameUtils.make_valid_attr_name_from_method_name method_name
        "#{self.aspect_method_prefix}#{class_or_object_prefix}advice_chain_#{type_or_object_key}_#{valid_name}"
      end
  
      def self.aspect_method_prefix
        "_aspect_"
      end
  
      def saved_method_name join_point
        to_key = Aquarium::Utils::NameUtils.make_type_or_object_key(join_point.type_or_object)
        "#{Aspect.aspect_method_prefix}saved_#{to_key}_#{join_point.method_name}"
      end
  
      def specified_advice_kinds
        @specification.keys.select do |key|
          Aquarium::Aspects::Advice.kinds.include? key
        end
      end
  
      def rationalize_parameters opts
        return unless opts.last.kind_of?(Hash)
        option_synonyms = { 
          :type             => :types,
          :within_type      => :types, 
          :within_types     => :types,
          :object           => :objects,
          :within_object    => :objects, 
          :within_objects   => :objects,
          :method           => :methods,
          :within_method    => :methods, 
          :within_methods   => :methods,
          :pointcut         => :pointcuts,
          :within_pointcut  => :pointcuts,
          :within_pointcuts => :pointcuts
        }
        hash = opts.pop.dup
        opts.push hash
        option_synonyms.each do |syn, actual|
          if hash.has_key? syn
            hash[actual] = make_array(hash[actual], hash[syn])
            hash.delete syn
          end
        end
        # Only one advice argument allowed.
        unless hash.has_key?(:advice)
          advice_synonyms = {
            :call            => :advice,
            :invoke          => :advice,
            :advise_with     => :advice
          }
          advice_synonyms.each do |syn, actual|
            if hash.has_key? syn
              hash[actual] = hash[syn]
              hash.delete syn
            end
          end
        end
        [:types, :objects, :methods, :method_options, :pointcuts, :default_object].each do |opt|
          hash[opt] = Set.new(make_array(hash[opt]))
        end
        opts
      end
      
      def validate_specification 
        bad_options("One of #{Aquarium::Aspects::Advice.kinds.inspect} is required.") unless advice_kinds_given?
        bad_options(":around can't be used with :before.") if around_given_with? :before
        bad_options(":around can't be used with :after.")  if around_given_with? :after
        bad_options(":around can't be used with :after_returning.")  if around_given_with? :after_returning
        bad_options(":around can't be used with :after_raising.")    if around_given_with? :after_raising
        bad_options(":after can't be used with :after_returning.")   if after_given_with? :after_returning
        bad_options(":after can't be used with :after_raising.")     if after_given_with? :after_raising
        bad_options(":after_returning can't be used with :after_raising.") if after_returning_given_with? :after_raising
        unless pointcuts_given? or types_given? or objects_given? #or objects_given_excluding_default?
          bad_options("At least one of :pointcut(s), :type(s), :object(s) is required.") 
        end
        if pointcuts_given? and (types_given? or objects_given?)
          bad_options("Can't specify both :pointcut(s) and one or more of :type(s), and/or :object(s).") 
        end
        # unless methods_given? or pointcuts_given? or types_given? #or objects_given_excluding_default?
        #   specification_too_short
        # end
      end

      def advice_kinds_given
        Aquarium::Aspects::Advice.kinds.inject([]) {|ary, kind| ary << @specification[kind] if @specification[kind]; ary}
      end

      def advice_kinds_given?
        not advice_kinds_given.empty?
      end

      def around_given_with? other_advice_kind_sym
        @specification[:around] and @specification[other_advice_kind_sym]
      end
  
      def after_given_with? other_advice_kind_sym
        @specification[:after] and @specification[other_advice_kind_sym]
      end
      def after_returning_given_with? other_advice_kind_sym
        @specification[:after_returning] and @specification[other_advice_kind_sym]
      end
  
      %w[pointcuts types objects methods attributes method_options attribute_options].each do |name|
        class_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}_given
            @specification[:#{name}]
          end
  
          def #{name}_given?
            not (#{name}_given.nil? or #{name}_given.empty?)
          end
        EOF
      end
      
      def use_first_nonadvice_symbol_as_method options
        2.times do |i|
          if options.size >= i+1
            sym = options[i]
            if sym.kind_of?(Symbol) && !Aquarium::Aspects::Advice::kinds.include?(sym)
              @specification[:methods] = Set.new([sym])
              return
            end
          end
        end
      end
      
      def bad_options message
        raise Aquarium::Utils::InvalidOptions.new("Invalid options given. " + message + " (options: #{@original_options.inspect})")
      end
    end
  end
end
