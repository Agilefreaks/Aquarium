# A simple Design by Contract module. Adds advice to test that the contract, which is specified with
# a block passes. Note that it doesn't attempt to handle the correct behavior under contract 
# inheritance (TODO).

require 'aquarium'

module Aquarium
  module Extras
    module DesignByContract
      
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
        around *args do |jp, *args2|
          DesignByContract.test_condition "invariant failure (before invocation): #{message}", jp, *args2, &contract_block
          jp.proceed
          DesignByContract.test_condition "invariant failure (after invocation): #{message}", jp, *args2, &contract_block
        end
      end

      private

      def self.test_condition message, jp, *args
        unless yield(jp, *args)
          raise ContractError.new(message)
        end
      end
      
      def add_advice kind, test_kind, message, *args, &contract_block
        self.send(kind, *args) do |jp, *args2|
          DesignByContract.test_condition "#{test_kind} failure: #{message}", jp, *args2, &contract_block
        end
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

