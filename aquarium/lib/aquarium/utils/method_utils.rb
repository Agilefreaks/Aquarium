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
      
      def self.visibility type_or_instance, method_sym, class_or_instance_only = nil
        meta_method_suffixes = determine_meta_method_suffixes type_or_instance, class_or_instance_only
        meta_method_suffixes.each do |suffix|
          %w[public protected private].each do |protection|
            meta_method = "#{protection}_#{suffix}"
            if find_method(type_or_instance, method_sym, meta_method)
              return protection.intern
            end
          end
        end
        nil
      end

      private
      def self.determine_meta_method_suffixes2 type_or_instance, class_or_instance_only
        ["method_defined"]
      end
      
      def self.determine_meta_method_suffixes type_or_instance, class_or_instance_only
        limits = class_or_instance_only.nil? ? [:instance_method_only, :class_method_only] : [class_or_instance_only]
        meta_method_suffixes = []
        limits.each do |limit|
          if (type_or_instance.kind_of?(Class) || type_or_instance.kind_of?(Module))
            meta_method_suffixes << "instance_methods" if limit == :instance_method_only
            meta_method_suffixes << "methods"          if limit == :class_method_only
          else
            meta_method_suffixes << "methods"          if limit == :instance_method_only
          end
        end
        meta_method_suffixes
      end
      
      def self.find_method2 type_or_instance, method_sym, meta_method
        type_or_instance.send(meta_method, method_sym.to_s)
      end
      
      def self.find_method type_or_instance, method_sym, meta_method
        type_or_instance.send(meta_method).include?(method_sym.to_s)
      end
    end
  end
end
