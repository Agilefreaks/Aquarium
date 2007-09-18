# A simple Design by Contract module. Adds advice to test that the contract, which is specified with
# a block passes. Note that it doesn't attempt to handle the correct behavior under contract 
# inheritance (TODO).
# Warning: This module automatically includes Aquarium::Aspects::DSL::AspectDSL into the class with 
# the contract and it adds the :precondition, :postcondition, and the :invariant methods to Object! 
require 'aquarium'

module Aquarium
  module Extras
    module DesignByContract
      include Aquarium::Aspects
            
      class ContractError < Exception
        def initialize(message)
          super
        end
      end
      
      def precondition *args, &contract_block
        message = handle_message_arg args
        add_advice :before, "precondition", message, *args, &contract_block
      end

      def postcondition *args, &contract_block
        message = handle_message_arg args
        add_advice :after_returning, "postcondition", message, *args, &contract_block
      end

      def invariant *args, &contract_block
        message = handle_message_arg args
        Aspect.new make_args(:around, *args) do |jp, *params|
          DesignByContract.test_condition "invariant failure (before invocation): #{message}", jp, *params, &contract_block
          jp.proceed
          DesignByContract.test_condition "invariant failure (after invocation): #{message}", jp, *params, &contract_block
        end
      end

      private

      def self.test_condition message, jp, *args
        unless yield(jp, *args)
          raise ContractError.new(message)
        end
      end
      
      def add_advice kind, test_kind, message, *args, &contract_block
        Aspect.new make_args(kind, *args) do |jp, *params|
          DesignByContract.test_condition "#{test_kind} failure: #{message}", jp, *params, &contract_block
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

