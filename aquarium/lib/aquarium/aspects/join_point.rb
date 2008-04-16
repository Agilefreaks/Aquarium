require 'aquarium/utils'
  
def bad_attributes message, options
  raise Aquarium::Utils::InvalidOptions.new("Invalid attributes. " + message + ". Options were: #{options.inspect}")
end

module Aquarium
  module Aspects
    class JoinPoint

      class ProceedMethodNotAvailable < Exception; end
      class ContextNotDefined < Exception; end
      
      class Context
        attr_accessor :advice_kind, :advised_object, :parameters, :block_for_method, :returned_value, :raised_exception, :proceed_proc, :current_advice_node

        alias :target_object  :advised_object
        alias :target_object= :advised_object=
        
        # Create a join point object. It must have one and only type _or_ object and one method or the special keywords <tt>:all</tt>.
        # Usage:
        #  join_point = JoinPoint.new.find :type => ..., :method_name => ... [, (:class_method | :instance_method) => (true | false) ]
        # where
        # <tt>:type => type_or_type_name_or_regexp</tt>::
        #   A single type, type name or regular expression matching only one type. One and only one
        #   type _or_ object is required. An error is raised otherwise.
        #
        # <tt>:method_name => method_name_or_sym</tt>::
        # <tt>:method => method_name_or_sym</tt>::
        #   A single method name or symbol. Only one is allowed, although the special flag <tt>:all</tt> is allowed.
        #
        # <tt>(:class_method | :instance_method) => (true | false)</tt>::
        #   Is the method a class or instance method? Defaults to <tt>:instance_method => true</tt>.
        def initialize options
          update options
          assert_valid options
        end

        def update options
          options.each do |key, value|
            instance_variable_set "@#{key}", value
          end
        end
    
        def proceed enclosing_join_point, *args, &block
          raise ProceedMethodNotAvailable.new("It looks like you tried to call \"JoinPoint#proceed\" (or \"JoinPoint::Context#proceed\") from within advice that isn't \"around\" advice. Only around advice can call proceed. (Specific error: JoinPoint#proceed cannot be called because no \"@proceed_proc\" attribute was set on the corresponding JoinPoint::Context object.)") if @proceed_proc.nil?
          do_invoke proceed_proc, :call, enclosing_join_point, *args, &block
        end
        
        def invoke_original_join_point enclosing_join_point, *args, &block
          do_invoke current_advice_node, :invoke_original_join_point, enclosing_join_point, *args, &block
        end
        
        def do_invoke proc_to_send, method, enclosing_join_point, *args, &block
          args = parameters if (args.nil? or args.size == 0)
          enclosing_join_point.context.block_for_method = block if block 
          proc_to_send.send method, enclosing_join_point, advised_object, *args
        end
        protected :do_invoke
        
        alias :to_s :inspect
    
        # We require the same object id, not just equal objects.
        def <=> other
          return 0 if object_id == other.object_id 
          return 1 if other.nil?
          result = self.class <=> other.class 
          return result unless result == 0
          result = (self.advice_kind.nil? and other.advice_kind.nil?) ? 0 : self.advice_kind <=> other.advice_kind 
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
    
        protected
    
        def assert_valid options
          bad_attributes("Must specify an :advice_kind", options)    unless advice_kind
          bad_attributes("Must specify an :advised_object", options) unless advised_object
          bad_attributes("Must specify a :parameters", options)      unless parameters
        end    
      end

      attr_accessor :target_type, :target_object, :method_name, :visibility, :context
      attr_reader   :instance_or_class_method
      
      def instance_method?
        @instance_method
      end
      
      def class_method?
        !@instance_method
      end
      
      def initialize options = {}
        @target_type     = resolve_type options
        @target_object   = options[:object]
        @method_name     = options[:method_name] || options[:method]
        class_method     = options[:class_method].nil? ? false : options[:class_method]
        @instance_method = options[:instance_method].nil? ? (!class_method) : options[:instance_method]
        @instance_or_class_method  = @instance_method ? :instance : :class
        @visibility = Aquarium::Utils::MethodUtils.visibility(type_or_object, @method_name, class_or_instance_method_flag)
        assert_valid options
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
      
      # Invoke the "enclosed" join point, which could be aspect advice wrapping the original runtime join point.
      # This method can only be called if the join point has a context object defined that represents an actual
      # runtime "state".
      def proceed *args, &block
        raise ContextNotDefined.new(":proceed can't be called unless the join point has a context object.") if context.nil?
        context.proceed self, *args, &block
      end

      # Invoke the actual runtime join point, skipping any intermediate advice.
      # This method can only be called if the join point has a context object defined that represents an actual
      # runtime "state".
      def invoke_original_join_point *args, &block
        raise ContextNotDefined.new(":invoke_original_join_point can't be called unless the join point has a context object.") if context.nil?
        context.invoke_original_join_point self, *args, &block
      end
      
      def make_current_context_join_point context_options
        new_jp = dup
        if new_jp.context.nil?
          new_jp.context = JoinPoint::Context.new context_options
        else
          new_jp.context = context.dup
          new_jp.context.update context_options
        end
        new_jp
      end

      # Needed for comparing this field in #compare_field
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
  
      NIL_OBJECT = Aquarium::Utils::NilObject.new  
    end
  end
end
