module Aquarium
  module Utils
    module TypeUtils
      def self.is_type? type_or_object
        type_or_object.kind_of?(Class) or type_or_object.kind_of?(Module)
      end

      def self.descendents clazz
        visited_types = [Class, Object, Module, clazz]
        Module.constants.inject([clazz]) do |result, const|
          mod = Module.class_eval(const)
          if mod.respond_to?(:ancestors)
            result << mod if mod.ancestors.include?(clazz)
            do_descendents clazz, mod, visited_types, result
          end
          result
        end.uniq
      end
      
      def self.descendents2 clazz
        visited_types = [Class, Object, clazz]
        result = [clazz]
        p "Module.constants: #{Module.constants.sort.inspect .gsub(/\</,"&lt;").gsub(/\>/,"&gt;")}<br/><br/>"
        do_descendents clazz, Module, visited_types, result
        result.flatten.uniq
      end
      
      protected
      
      def self.do_descendents clazz, visiting_module, visited, result
        # p "#{clazz}, #{visiting_module}<br/>"
        visited << visiting_module
        # TODO Odd ruby behavior; a class is constant on the class, yet if it is nested in a module
        # it comes up undefined! However, doing class_eval works around it. Is there a better way??
        visiting_module.constants.each do |const| 
          next unless visiting_module.const_defined?(const)
          clazz2 = visiting_module.const_get(const)
          # clazz2 = visiting_module.const_defined?(const) ? 
            # visiting_module.const_get(const) :
            # visiting_module.class_eval(const) 
          next if visited.include?(clazz2) or not clazz2.respond_to?(:ancestors)
          visited << clazz2
          result << clazz2 if clazz2.ancestors.include?(clazz)
          do_descendents clazz, clazz2, visited, result 
        end
      end
    end
  end
end