module Aquarium
  module Utils
    module MethodUtils
      def self.method_args_to_hash *args
        return {} if args.empty? || (args.size == 1 && args[0].nil?)
        hash = (args[-1] and args[-1].kind_of? Hash) ? args.pop : {}
        args.each do |arg|
          if block_given?
            hash[arg] = yield arg
          else 
            hash[arg] = nil
          end
        end
        hash
      end
    end
  end
end
