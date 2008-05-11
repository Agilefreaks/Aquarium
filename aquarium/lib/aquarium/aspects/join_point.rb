require 'aquarium/utils'
require 'aquarium/aspects/advice'
  
def bad_attributes message, options
  raise Aquarium::Utils::InvalidOptions.new("Invalid attributes. " + message + ". Options were: #{options.inspect}")
end

module Aquarium
  module Aspects
    # == JoinPoint
    # Encapsulates information about a Join Point that might be advised. JoinPoint objects are <i>almost</i> 
    # value objects; you can change the context object.
    # TODO Separate out the read-only part from the variable part. This might require an API change!
    class JoinPoint

      class ProceedMethodNotAvailable < Exception; end
      class ContextNotCorrectlyDefined < Exception; end
      
      # == JoinPoint::Context
      # Encapsulates current runtime context information for a join point, such as the values of method parameters, a raised 
      # exception (for <tt>:after</tt> or <tt>after_raising</tt> advice), <i>etc.</i>
      # Context objects are <i>partly</i> value objects. 
      # TODO Separate out the read-only part from the variable part. This might require an API change!
      class Context
        attr_accessor :advice_kind, :advised_object, :parameters, :proceed_proc, :current_advice_node
        attr_accessor :returned_value, :raised_exception, :block_for_method

        alias :target_object  :advised_object
        
        NIL_OBJECT = Aquarium::Utils::NilObject.new
        
        def initialize options = {}
          update options
        end

        def update options
          options.each do |key, value|
            instance_variable_set "@#{key}", value
          end
          @advice_kind    ||= Advice::UNKNOWN_ADVICE_KIND
          @advised_object ||= NIL_OBJECT
          @parameters     ||= []
        end
        
        def proceed enclosing_join_point, *args, &block
          raise ProceedMethodNotAvailable.new("It looks like you tried to call \"JoinPoint#proceed\" (or \"JoinPoint::Context#proceed\") from within advice that isn't \"around\" advice. Only around advice can call proceed. (Specific error: JoinPoint#proceed cannot be invoked because no \"@proceed_proc\" attribute was set on the corresponding JoinPoint::Context object.)") if @proceed_proc.nil?
          # do_invoke proceed_proc, :call, enclosing_join_point, *args, &block
          args = parameters if (args.nil? or args.size == 0)
          enclosing_join_point.context.block_for_method = block if block 
          proceed_proc.call enclosing_join_point, advised_object, *args, &block
        end
        
        def invoke_original_join_point enclosing_join_point, *args, &block
          raise ContextNotCorrectlyDefined.new("It looks like you tried to call \"JoinPoint#invoke_original_join_point\" (or \"JoinPoint::Context#invoke_original_join_point\") using a join point without a completely formed context object. (Specific error: The original join point cannot be invoked because no \"@current_advice_node\" attribute was set on the corresponding JoinPoint::Context object.)") if @current_advice_node.nil?
          # do_invoke current_advice_node, :invoke_original_join_point, enclosing_join_point, *args, &block
          args = parameters if (args.nil? or args.size == 0)
          enclosing_join_point.context.block_for_method = block if block 
          current_advice_node.invoke_original_join_point enclosing_join_point, advised_object, *args, &block
        end
        
        def do_invoke proc_to_send, method, enclosing_join_point, *args, &block
          args = parameters if (args.nil? or args.size == 0)
          enclosing_join_point.context.block_for_method = block if block 
          proc_to_send.send method, enclosing_join_point, advised_object, *args, &block
        end
        protected :do_invoke
        
        alias :to_s :inspect
    
        # We require the same object id, not just equal objects.
        def <=> other
          return 0 if object_id == other.object_id 
          return 1 if other.nil?
          result = self.class <=> other.class 
          return result unless result == 0
          result = Advice.compare_advice_kinds self.advice_kind, other.advice_kind
          return result unless result == 0
          result = (self.advised_object.object_id.nil? and other.advised_object.object_id.nil?) ? 0 : self.advised_object.object_id <=> other.advised_object.object_id 
          return result unless result == 0
          result = (self.parameters.nil? and other.parameters.nil?) ? 0 : self.parameters <=> other.parameters 
          return result unless result == 0
          result = (self.returned_value.nil? and other.returned_value.nil?) ? 0 : self.returned_value <=> other.returned_value 
          return result unless result == 0
          (self.raised_exception.nil? and other.raised_exception.nil?) ? 0 : self.raised_exception <=> other.raised_exception
        end
    
        def eql? other
          (self <=> other) == 0
        end

        alias :==  :eql?
        alias :=== :eql?
    
      end

      attr_accessor :context
      attr_reader   :target_type, :target_object, :method_name, :visibility, :instance_or_class_method
      
      def instance_method?
        @instance_method
      end
      
      def class_method?
        !@instance_method
      end
      
      # Create a join point object, specifying either one type or one object and a method. 
      # Only method join points are currently supported by Aquarium.
      # 
      # The supported options are
      # <tt>:type => type | type_name | type_name_regexp</tt>::
      #   A single type, type name or regular expression matching only one type. One and only one
      #   type _or_ object is required. An error is raised otherwise.
      # <tt>:object => object</tt>::
      #   A single object. One and only one type _or_ object is required. An error is raised otherwise.
      # <tt>:method_name | :method => method_name_or_symbol</tt>::
      #   A single method name or symbol. Only one is allowed, although the special flag <tt>:all</tt> 
      #   is allowed, as long as only one method will be found, subject to the next option.
      # <tt>:class_method | :instance_method => true | false</tt>::
      #   Is the method a class or instance method? Defaults to <tt>:instance_method => true</tt>.
      # 
      # Note: The range of options is not as rich as for Pointcut, because it is expected that JoinPoint objects
      # will be explicitly created only rarely by users of Aquarium. Most of the time, Pointcuts will be created.
      def initialize options = {}
        @target_type     = resolve_type options
        @target_object   = options[:object]
        @method_name     = options[:method_name] || options[:method]
        class_method     = options[:class_method].nil? ? false : options[:class_method]
        @instance_method = options[:instance_method].nil? ? (!class_method) : options[:instance_method]
        @instance_or_class_method  = @instance_method ? :instance : :class
        @visibility = Aquarium::Utils::MethodUtils.visibility(type_or_object, @method_name, class_or_instance_method_flag)
        @context = options[:context] || JoinPoint::Context.new
        assert_valid options
      end
  
      def dup
        jp = super
        jp.context = @context.dup unless @context.nil?
        jp
      end
      
      def type_or_object
        target_type || target_object
      end
      
      alias_method :target_type_or_object, :type_or_object

      def exists?
        type_or_object_sym = @target_type ? :type : :object
        results = Aquarium::Finders::MethodFinder.new.find type_or_object_sym => type_or_object, 
                            :method => method_name, 
                            :method_options => [visibility, instance_or_class_method]
        raise Aquarium::Utils::LogicError("MethodFinder returned more than one item! #{results.inspect}") if (results.matched.size + results.not_matched.size) != 1
        return results.matched.size == 1 ? true : false
      end
      
      # Invoke the join point itself (which could actually be aspect advice wrapping the original join point...).
      # This method can only be called if the join point has a context object defined that represents an actual
      # runtime "state".
      def proceed *args, &block
        raise ContextNotCorrectlyDefined.new(":proceed can't be called unless the join point has a context object.") if context.nil?
        context.proceed self, *args, &block
      end

      # Invoke the join point itself, skipping any intermediate advice.
      # This method can only be called if the join point has a context object defined that represents an actual
      # runtime "state".
      # Use this method cautiously, at it could be "surprising" if some advice is not executed!
      def invoke_original_join_point *args, &block
        raise ContextNotCorrectlyDefined.new(":invoke_original_join_point can't be called unless the join point has a context object.") if context.nil?
        context.invoke_original_join_point self, *args, &block
      end
      
      def instance_method
        @instance_method
      end
      
      # We require the same object id, not just equal objects.
      def <=> other
        return 0  if object_id == other.object_id 
        return 1  if other.nil?
        result = self.class <=> other.class
        return result unless result == 0
        result = compare_field(:target_object, other) {|f1,f2| f1.object_id <=> f2.object_id}
        return result unless result == 0
        result = compare_field(:instance_method, other) {|f1,f2| boolean_compare(f1,f2)}
        return result unless result == 0
        [:target_type, :method_name, :context].each do |field|
          result = compare_field field, other
          return result unless result == 0
        end
        0
      end

      def eql? other
        return (self <=> other) == 0
      end
  
      alias :==  :eql?
      alias :=== :eql?
  
      def inspect
        "JoinPoint: {target_type = #{target_type.inspect}, target_object = #{target_object.inspect}, method_name = #{method_name}, instance_method? #{instance_method?}, context = #{context.inspect}}"
      end
  
      alias :to_s :inspect

  
      protected
  
      def compare_field field_reader, other
        field1 = self.method(field_reader).call
        field2 = other.method(field_reader).call
        if field1.nil? 
          return field2.nil? ? 0 : -1
        else
          return 1 if field2.nil?
        end
        block_given? ? (yield field1, field2) : (field1 <=> field2)
      end
      
      def boolean_compare b1, b2
        return 0 if b1 == b2
        return b1 == true ? 1 : -1
      end
      
      def resolve_type options
        type = options[:type]
        return type if type.nil?  # okay, if they specified an object!
        return type if type.kind_of? Module
        found = Aquarium::Finders::TypeFinder.new.find :type => type
        if found.matched.empty?
          bad_attributes("No type matched the string or regular expression: #{type.inspect}", options)
        elsif found.matched.size > 1
          bad_attributes("More than one type matched the string or regular expression: #{type.inspect}", options)
        end
        found.matched.keys.first
      end

      # Since JoinPoints can be declared for non-existent methods, tolerate "nil" for the visibility.
      def assert_valid options, error_message = ""
        error_message << "Must specify a :method_name. "            unless method_name
        error_message << "Must specify either a :type or :object. " unless (target_type or  target_object)
        error_message << "Can't specify both a :type or :object. "  if     (target_type and target_object)
        bad_attributes(error_message, options) if error_message.length > 0
      end

      def class_or_instance_method_flag
        "#{instance_or_class_method.to_s}_method_only".intern
      end
    
      public
  
      # A "convenience" JoinPoint supporting the "Null Object Pattern."
      NIL_OBJECT = Aquarium::Utils::NilObject.new  
    end
  end
end
