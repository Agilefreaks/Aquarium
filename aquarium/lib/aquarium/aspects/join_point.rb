require 'aquarium/utils'
  
def bad_attributes message, options
  raise Aquarium::Utils::InvalidOptions.new("Invalid attributes. " + message + ". Options were: #{options.inspect}")
end

module Aquarium
  module Aspects
    class JoinPoint

      class Context
        attr_accessor :advice_kind, :advised_object, :parameters, :block_for_method, :returned_value, :raised_exception, :proceed_proc

        alias :target_object  :advised_object
        alias :target_object= :advised_object=
        
        def initialize options
          update options
          assert_valid options
        end

        def update options
          options.each do |key, value|
            instance_variable_set "@#{key}".intern, value
          end
        end
    
        def proceed enclosing_join_point, *args, &block
          raise "JoinPoint#proceed can only be called if @proceed_proc is set." unless @proceed_proc
          args = parameters if (args.nil? or args.size == 0)
          enclosing_join_point.context.block_for_method = block if block 
          proceed_proc.call enclosing_join_point, *args
        end
        protected :proceed
        
        alias :to_s :inspect
    
        # We require the same object id, not just equal objects.
        def <=> other
          return 0 if object_id == other.object_id 
          result = self.class <=> other.class 
          return result unless result == 0
          result = (self.advice_kind.nil? && other.advice_kind.nil?) ? 0 : self.advice_kind <=> other.advice_kind 
          return result unless result == 0
          result = (self.advised_object.object_id.nil? && other.advised_object.object_id.nil?) ? 0 : self.advised_object.object_id <=> other.advised_object.object_id 
          return result unless result == 0
          result = (self.parameters.nil? && other.parameters.nil?) ? 0 : self.parameters <=> other.parameters 
          return result unless result == 0
          result = (self.returned_value.nil? && other.returned_value.nil?) ? 0 : self.returned_value <=> other.returned_value 
          return result unless result == 0
          (self.raised_exception.nil? && other.raised_exception.nil?) ? 0 : self.raised_exception <=> other.raised_exception
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

      attr_accessor :type, :object, :method_name, :context
  
      def is_instance_method?
        @is_instance_method
      end
      
      def initialize options = {}
        @type        = options[:type]
        @object      = options[:object]
        @method_name = options[:method_name] || options[:method]
        @is_instance_method = options[:is_instance_method]
        is_class_method = options[:is_class_method].nil? ? false : options[:is_class_method]
        @is_instance_method = (!is_class_method) if @is_instance_method.nil?
        assert_valid options
      end
  
      # deal with warnings for Object#type being obsolete:
      def get_type
        @type
      end
  
      def type_or_object
        @type || @object
      end
  
      # TODO while convenient, it couples advice-type information where it doesn't belong!
      def proceed *args, &block
        context.method(:proceed).call self, *args, &block
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

      # We require the same object id, not just equal objects.
      def <=> other
        return 0 if object_id == other.object_id 
        result = self.class <=> other.class 
        return result unless result == 0
        result = (self.get_type.nil? && other.get_type.nil?) ? 0 : self.get_type.to_s <=> other.get_type.to_s 
        return result unless result == 0
        result = (self.object.object_id.nil? && other.object.object_id.nil?) ? 0 : self.object.object_id <=> other.object.object_id 
        result = self.object.object_id <=> other.object.object_id
        return result unless result == 0
        result = (self.method_name.nil? && other.method_name.nil?) ? 0 : self.method_name.to_s <=> other.method_name.to_s 
        return result unless result == 0
        result = self.is_instance_method? == other.is_instance_method?
        return 1 unless result == true
        result = (self.context.nil? && other.context.nil?) ? 0 : self.context <=> other.context 
        return result
      end

      def eql? other
        return (self <=> other) == 0
      end
  
      alias :==  :eql?
      alias :=== :eql?
  
      def inspect
        "JoinPoint: {type = #{type.inspect}, object = #{object.inspect}, method_name = #{method_name}, is_instance_method? #{is_instance_method?}, context = #{context.inspect}}"
      end
  
      alias :to_s :inspect

  
      protected
  
      def assert_valid options
        error_message = ""
        error_message << "Must specify a :method_name. "            unless method_name
        error_message << "Must specify either a :type or :object. " unless (type or  object)
        error_message << "Can't specify both a :type or :object. "  if     (type and object)
        bad_attributes(error_message, options) if error_message.length > 0
      end
  
      public
  
      NIL_OBJECT = Aquarium::Utils::NilObject.new  
    end
  end
end
