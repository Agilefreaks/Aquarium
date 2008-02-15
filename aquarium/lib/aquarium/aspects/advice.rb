require 'aquarium/utils/array_utils'
require 'aquarium/extensions/string'
require 'aquarium/extensions/symbol'
require 'aquarium/utils/invalid_options'
require 'aquarium/utils/nil_object'

module Aquarium
  module Aspects
    module Advice
      
      KINDS_IN_PRIORITY_ORDER = [:around, :before, :after, :after_returning, :after_raising] 
      
      def self.kinds; KINDS_IN_PRIORITY_ORDER; end

      def self.sort_by_priority_order advice_kinds
        advice_kinds.sort do |x,y| 
          KINDS_IN_PRIORITY_ORDER.index(x.to_sym) <=> KINDS_IN_PRIORITY_ORDER.index(y.to_sym)
        end.map {|x| x.to_sym}
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
      end
  
      def call jp, obj, *args
        do_call @proc, "", jp, obj, *args
      end

      def invoke_original_join_point current_jp, obj, *args
        do_call last, "While executing the original join_point: ", current_jp, obj, *args
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
      protected :do_call
      
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
          method = invoking_object(jp).method(@alias_method_name)
          block_for_method.nil? ? 
            invoking_object(jp).send(@alias_method_name, *args) : 
            invoking_object(jp).send(@alias_method_name, *args, &block_for_method)
          # Buggy!!
          # method = invoking_object.method(@alias_method_name)
          # block_for_method.nil? ? 
          #   method.call(*args) : 
          #   method.call(*args, &block_for_method)
        }
      end
    end

    class BeforeAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          before_jp = jp.make_current_context_join_point :advice_kind => :before, :current_advice_node => self
          advice.call(before_jp, obj, *args)
          next_node.call(jp, obj, *args)
        }
      end
    end

    class AfterReturningAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          returned_value = next_node.call(jp, obj, *args)
          next_jp = jp.make_current_context_join_point :advice_kind => :after_returning, :returned_value => returned_value, :current_advice_node => self
          advice.call(next_jp, obj, *args)
          next_jp.context.returned_value   # allow advice to modify the returned value
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
              next_jp = jp.make_current_context_join_point :advice_kind => :after_raising, :raised_exception => raised_exception, :current_advice_node => self
              advice.call(next_jp, obj, *args)
              raised_exception = next_jp.context.raised_exception   # allow advice to modify raised exception
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
          # advice.call is invoked in each bloc, rather than once in an "ensure" clause, so the invocation in the rescue class
          # can allow the advice to change the exception that will be raised.
          begin
            returned_value = next_node.call(jp, obj, *args)
            next_jp = jp.make_current_context_join_point :advice_kind => :after, :returned_value => returned_value, :current_advice_node => self
            advice.call(next_jp, obj, *args)
            next_jp.context.returned_value   # allow advice to modify the returned value
          rescue Object => raised_exception
            next_jp = jp.make_current_context_join_point :advice_kind => :after, :raised_exception => raised_exception, :current_advice_node => self
            advice.call(next_jp, obj, *args)
            raise next_jp.context.raised_exception
          end
        }
      end
    end

    class AroundAdviceChainNode < AdviceChainNode
      def initialize options = {}
        super(options) { |jp, obj, *args| 
          around_jp = jp.make_current_context_join_point :advice_kind => :around, :proceed_proc => next_node, :current_advice_node => self
          advice.call(around_jp, obj, *args)
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
