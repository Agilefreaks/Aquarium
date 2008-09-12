require 'aquarium'

module Aquarium
  # == Extras
  # These modules are <i>not</i> included automatically when you <tt>require 'aquarium'</tt>. You have to
  # include them explicitly.
  module Extras
    # A simple Design by Contract module. Adds advice to test that the contract, which is specified with
    # a block passes. Note that it doesn't attempt to handle the correct behavior under contract 
    # inheritance. A usage example is included in the Examples as part of the distribution and it is also
    # shown on the web site.
    # Normally, you want to disable the contracts in production runs, so you avoid the overhead. To do this
    # effectively, call DesignByContract.disable_all before any contracts are created. That will prevent
    # all of the aspects from being created along with their overhead.
    # *Warning*: This module automatically includes Aquarium::DSL into the class with 
    # the contract and it adds the :precondition, :postcondition, and the :invariant methods to Object! 
    module DesignByContract
      include Aquarium::Aspects
            
      class ContractError < Exception
        def initialize(message)
          super
        end
      end
      
      @@enabled = true

      # Enable creation and execution of contracts
      def self.enable_all
        @@enabled = true
      end
      
      # Disable creation of any subsequent contracts and disable execution of
      # existing contracts. That is, while contracts are disabled, it no existing
      # contracts will be executed and any attempts to define new contracts will be ignored.
      def self.disable_all
        @@enabled = false
      end
      
      def precondition *args, &contract_block
        return unless @@enabled
        message = handle_message_arg args
        add_advice :before, "precondition", message, *args, &contract_block
      end

      def postcondition *args, &contract_block
        return unless @@enabled
        message = handle_message_arg args
        add_advice :after_returning, "postcondition", message, *args, &contract_block
      end

      def invariant *args, &contract_block
        return unless @@enabled
        message = handle_message_arg args
        Aspect.new make_args(:around, *args) do |jp, obj, *params|
          DesignByContract.test_condition "invariant failure (before invocation): #{message}", jp, obj, *params, &contract_block
          result = jp.proceed
          DesignByContract.test_condition "invariant failure (after invocation): #{message}", jp, obj, *params, &contract_block
          result
        end
      end

      private

      def self.test_condition message, jp, obj, *args
        if @@enabled and yield(jp, obj, *args) == false
          raise ContractError.new(message)
        end
      end
      
      def add_advice kind, test_kind, message, *args, &contract_block
        Aspect.new make_args(kind, *args) do |jp, obj, *params|
          DesignByContract.test_condition "#{test_kind} failure: #{message}", jp, obj, *params, &contract_block
        end
      end
      
      def make_args advice_kind, *args
        args2 = args.dup.unshift advice_kind
        args2 << {} unless args2.last.kind_of?(Hash)
        args2.last[:type] = self.name
        args2
      end
      
      def handle_message_arg args
        options = args[-1]
        return unless options.kind_of?(Hash)
        message = options[:message]
        options.delete :message 
        message || "(no error message)"
      end
    end
  end
end

class Object
  include Aquarium::Extras::DesignByContract
end

