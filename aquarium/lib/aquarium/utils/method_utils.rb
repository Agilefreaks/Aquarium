require 'aquarium/utils/type_utils'
require 'aquarium/utils/logic_error'

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

      def self.visibility type_or_instance, method_sym, class_or_instance_only = nil, include_ancestors = true
        find_method(type_or_instance, method_sym, class_or_instance_only, include_ancestors) do |type_or_instance, method_sym, protection| 
          return protection
        end
      end
      
      def self.has_method type_or_instance, method_sym, class_or_instance_only = nil, include_ancestors = true
        found = find_method(type_or_instance, method_sym, class_or_instance_only, include_ancestors) do |type_or_instance, method_sym, protection| 
          return true
        end 
        found ? true : false   # found could be nil; return false, if so
      end
      
      def self.find_method type_or_instance, method_sym, class_or_instance_only = nil, include_ancestors = true
        meta_method_suffixes = determine_meta_method_suffixes type_or_instance, class_or_instance_only
        meta_method_suffixes.each do |suffix|
          %w[public protected private].each do |protection|
            meta_method = "#{protection}_#{suffix}"
            methods = type_or_instance.send(meta_method, include_ancestors)
            if methods.include?(method_sym.to_s)
              return yield(type_or_instance, method_sym, protection.intern)
            end
          end
        end
        nil
      end

      # Which type in a hierarchy actually defines a method?
      def self.definer type_or_instance, method_sym, class_or_instance_only = nil
        return nil if type_or_instance.nil? or method_sym.nil? 
        return nil unless has_method(type_or_instance, method_sym, class_or_instance_only)
        ancestors  = ancestors_for type_or_instance
        determine_definer ancestors, type_or_instance, method_sym, class_or_instance_only
      end
      
      private
      
      # For objects, include the singleton/eigenclass in case a method of interest was actually defined just for the object.
      def self.ancestors_for object
        if Aquarium::Utils::TypeUtils.is_type? object
          object.ancestors
        else
          eigen = (class << object; self; end)
          [eigen] + eigen.ancestors
        end
      end
      
      def self.determine_definer ancestors, type_or_instance, method_sym, class_or_instance_only
        candidates = ancestors.find_all {|a| has_method(a, method_sym, class_or_instance_only, false) { true }}
        if candidates.size == 2 and Aquarium::Utils::TypeUtils.is_type?(type_or_instance) == false
          return determine_actual_parent(type_or_instance, candidates)
        end
        candidates.size == 1 ? candidates.first : raise(Aquarium::Utils::LogicError.new("Bug: Got multiple types #{candidates.inspect} that implement method #{method_sym}"))
      end
      
      def self.determine_actual_parent object, candidates
        return nil unless (object.is_a?(candidates[0]) and object.is_a?(candidates[1]))
        candidates[0].name == "" ? candidates[1] : candidates[0]
      end
      
      def self.determine_meta_method_suffixes type_or_instance, class_or_instance_only
        limits = class_or_instance_only.nil? ? [:instance_method_only, :class_method_only] : [class_or_instance_only]
        meta_method_suffixes = []
        limits.each do |limit|
          if Aquarium::Utils::TypeUtils.is_type? type_or_instance
            meta_method_suffixes << "instance_methods" if limit == :instance_method_only
            meta_method_suffixes << "methods"          if limit == :class_method_only
          else
            meta_method_suffixes << "methods"          if limit == :instance_method_only
          end
        end
        meta_method_suffixes
      end
    end
  end
end
