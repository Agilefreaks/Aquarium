module Aquarium
  module Utils
    module TypeUtils
      def self.is_type? type_or_object
        type_or_object.kind_of?(Class) or type_or_object.kind_of?(Module)
      end

      def self.descendents clazz
        visited_types = [Class, Object, Module, clazz]
        result = [clazz]
        Module.constants.each do |const|
          mod = Module.class_eval(const)
          if mod.respond_to?(:ancestors)
            result << mod if mod.ancestors.include?(clazz)
            do_descendents clazz, mod, visited_types, result
          end
        end
        result.uniq
      end
      
      protected
      
      def self.do_descendents clazz, visiting_module, visited, result
        visited << visiting_module
        # For JRuby classes, we have to "__x__" forms of the reflection methods that don't end in '?'. 
        # That includes "send", so we do some ugly switching, rather than call "mod.send(method_name)"!
        constants_method = determine_constants_method visiting_module
        nested_constants = constants_method == :constants ? visiting_module.constants : visiting_module.__constants__
        nested_constants.each do |const|
          next unless visiting_module.const_defined?(const)
          nested_module = constants_method == :constants ? visiting_module.const_get(const) : visiting_module.__const_get__(const)
          next if visited.include?(nested_module)
          visited << nested_module
          ancestors_method = determine_ancestors_method nested_module
          next if ancestors_method.nil?
          result << nested_module if nested_module.send(ancestors_method).include?(clazz)
          do_descendents clazz, nested_module, visited, result 
        end
      end
      
      def self.determine_constants_method mod
        mod.respond_to?(:__constants__) ? :__constants__ : :constants
      end
      
      def self.determine_ancestors_method mod
        return :__ancestors__ if mod.respond_to? :__ancestors__
        return :ancestors     if mod.respond_to? :ancestors
        nil
      end
    end
  end
end