require 'aquarium/utils/array_utils'
require 'aquarium/extensions/string'
require 'aquarium/extensions/symbol'
require 'aquarium/utils/invalid_options'
require 'aquarium/utils/nil_object'

module Aquarium
  module Aspects
    module Advice
      
      UNKNOWN_ADVICE_KIND = "unknown"

      KINDS_IN_PRIORITY_ORDER = [:around, :before, :after, :after_returning, :after_raising] 
      
      def self.kinds; KINDS_IN_PRIORITY_ORDER; end

      def self.sort_by_priority_order advice_kinds
        advice_kinds.sort do |x,y| 
          KINDS_IN_PRIORITY_ORDER.index(x.to_sym) <=> KINDS_IN_PRIORITY_ORDER.index(y.to_sym)
        end.map {|x| x.to_sym}
      end
      
      def self.compare_advice_kinds kind1, kind2
        if kind1.nil?
          return kind2.nil? ? 0 : -1
        end
        return 1 if kind2.nil?
        if kind1.eql?(UNKNOWN_ADVICE_KIND)
          return kind2.eql?(UNKNOWN_ADVICE_KIND) ? 0 : -1
        else
          return kind2.eql?(UNKNOWN_ADVICE_KIND) ? 1 : KINDS_IN_PRIORITY_ORDER.index(kind1) <=> KINDS_IN_PRIORITY_ORDER.index(kind2)
        end
      end
      
    end  

    # Supports Enumerable, but not the sorting methods, as this class is a linked list structure.
    # This is of limited usefulness, because you wouldn't use an iterator to invoke the procs
    # in the chain, because each proc will invoke the next node arbitrarily or possibly not at all
    # in the case of around advice!
    class AdviceChainNode 
      include Enumerable
      def initialize options = {}, &proc_block
        raise Aquarium::Utils::InvalidOptions.new("You must specify an advice block or Proc") if proc_block.nil?
        @proc = Proc.new &proc_block
        # assign :next_node and :static_join_point so the attributes are always created
        options[:next_node] ||= nil  
        options[:static_join_point] ||= nil
        options.each do |key, value|
          instance_variable_set "@#{key}".intern, value
          (class << self; self; end).class_eval(<<-EOF, __FILE__, __LINE__)
            attr_accessor(:#{key})
          EOF
        end
        
        # Bug #19262 workaround: need to only pass jp argument if arity is 1.
        def call_advice jp, obj, *args
          advice.arity == 1 ? advice.call(jp) : advice.call(jp, obj, *args)
        end
      end
  
      def call jp, obj, *args
        do_call @proc, "", jp, obj, *args
      end
      
      def invoke_original_join_point current_jp, obj, *args
        do_call last, "While executing the original join_point: ", current_jp, obj, *args
      end
      
      # Supports Enumerable
      def each 
        node = self 
        while node.nil? == false 
          yield node 
          node = node.next_node 
        end 
      end
      
      def last
        last_node = nil
        each { |node| last_node = node unless node.nil? } 
        last_node
      end
      
      def size
        inject(0) {|memo, node| memo += 1}
      end
      
      def empty?
        next_node.nil?
      end
  
      def inspect &block
        block ? yield(self) : super 
      end
  
      NIL_OBJECT = Aquarium::Utils::NilObject.new
      
      protected
      
      def invoking_object join_point
        join_point.instance_method? ? join_point.context.advised_object : join_point.target_type
      end

      #--
      # For performance reasons, we don't clone the context. 
      # There are potential concurrency issues, but note that the join point and its context object
      # are cloned at the start of the advice invocation, so concurrency problems should be rare, if
      # nonexistent.
      #++
      def update_current_context jp
        return if advice.arity == 0
        @last_advice_kind = jp.context.advice_kind
        @last_advice_node = jp.context.current_advice_node
        jp.context.current_advice_node = self
      end

      def reset_current_context jp 
        jp.context.advice_kind = @last_advice_kind
        jp.context.current_advice_node = @last_advice_node
      end
      
      def do_call proc_to, error_message_prefix, jp, obj, *args
        begin
          proc_to.call jp, obj, *args
        rescue => e
          class_or_instance_method_separater = jp.instance_method? ? "#" : "."
          context_message = error_message_prefix + "Exception raised while executing \"#{jp.context.advice_kind}\" advice for \"#{jp.type_or_object.inspect}#{class_or_instance_method_separater}#{jp.method_name}\": "
          backtrace = e.backtrace
          e2 = e.exception(context_message + e.message + " (join_point = #{jp.inspect})")
          e2.set_backtrace backtrace
          raise e2
        end
      end
    end

    # When invoking the original method, we use object.send(original_method_name, *args)
    # rather than object.method(...).call(*args). The latter fails when the original method
    # calls super. This is a Ruby bug: http://www.ruby-forum.com/topic/124276
    class NoAdviceChainNode < AdviceChainNode
      # Note that we extract the block passed to the original method call, if any, 
      # from the context and pass it to method invocation.
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          block_for_method = jp.context.block_for_method
          block_for_method.nil? ? 
            obj.send(@alias_method_name, *args) : 
            obj.send(@alias_method_name, *args, &block_for_method)
        }
      end
    end

    class BeforeAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          update_current_context jp
          jp.context.advice_kind = :before
          call_advice(jp, obj, *args)
          reset_current_context jp
          next_node.call(jp, obj, *args)
        }
      end
    end

    class AfterReturningAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          returned_value = next_node.call(jp, obj, *args)
          update_current_context jp
          jp.context.advice_kind = :after_returning
          jp.context.returned_value = returned_value
          call_advice(jp, obj, *args)
          result = jp.context.returned_value   # allow advice to modify the returned value
          reset_current_context jp
          result
        }
      end
    end

    # Note that the advice is not invoked if the exception is not of a type specified when the advice was created.
    # However, the default is to advise all thrown objects.
    class AfterRaisingAdviceChainNode < AdviceChainNode
      include Aquarium::Utils::ArrayUtils
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          begin
            next_node.call(jp, obj, *args)
          rescue Object => raised_exception
            if after_raising_exceptions_list_includes raised_exception
              update_current_context jp
              jp.context.advice_kind = :after_raising
              jp.context.raised_exception = raised_exception
              call_advice(jp, obj, *args)
              raised_exception = jp.context.raised_exception   # allow advice to modify the raised exception
              reset_current_context jp
            end
            raise raised_exception
          end
        }
      end

      private
      def after_raising_exceptions_list_includes raised_exception
        after_raising_exceptions_list.find {|x| raised_exception.kind_of? x}
      end
  
      def after_raising_exceptions_list 
        list = @after_raising.kind_of?(Set) ? @after_raising.to_a : @after_raising
        (list.nil? || list.empty? || (list.size == 1 && list[0] == "")) ? [Object] : list
      end    
    end

    class AfterAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          # call_advice is invoked in each bloc, rather than once in an "ensure" clause, so the invocation in the rescue class
          # can allow the advice to change the exception that will be raised.
          begin
            returned_value = next_node.call(jp, obj, *args)
            update_current_context jp
            jp.context.advice_kind = :after
            jp.context.returned_value = returned_value
            call_advice(jp, obj, *args)
            result = jp.context.returned_value   # allow advice to modify the returned value
            reset_current_context jp
            result
          rescue Object => raised_exception
            update_current_context jp
            jp.context.advice_kind = :after
            jp.context.raised_exception = raised_exception
            call_advice(jp, obj, *args)
            raised_exception = jp.context.raised_exception   # allow advice to modify the raised exception
            reset_current_context jp
            raise raised_exception
          end
        }
      end
    end

    class AroundAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          update_current_context jp
          jp.context.advice_kind = :around
          jp.context.proceed_proc = next_node
          result = call_advice(jp, obj, *args)
          reset_current_context jp
          result
        }
      end
    end

    # The advice_kind argument must be one of the values returned by Advice.kinds or one of the special values
    # ":no" or ":none", signfying a node for which there is no advice, where the actual method being advised is 
    # called directly instead. This kind of node is normally used as the terminal leaf in the chain.
    module AdviceChainNodeFactory
      def self.make_node options = {}
        advice_kind = options[:advice_kind]
        raise Aquarium::Utils::InvalidOptions.new("Unknown advice kind specified: #{advice_kind}") unless valid(advice_kind)
        advice_kind = :no if advice_kind == :none
        advice_chain_node_name = advice_kind.to_s.to_camel_case + "AdviceChainNode"
        clazz = Aquarium::Aspects.const_get advice_chain_node_name
        clazz.new options
      end
  
      def self.valid advice_kind
        advice_kind == :no || advice_kind == :none || Advice.kinds.include?(advice_kind)
      end
    end
  end
end
