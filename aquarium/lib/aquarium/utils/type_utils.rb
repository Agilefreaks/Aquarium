module Aquarium
  module Utils
    module TypeUtils
      def self.is_type? type_or_object
        type_or_object.kind_of?(Class) or type_or_object.kind_of?(Module)
      end

      def self.descendents clazz
        do_descendents clazz, Class, ["Class", "Module", "Object", clazz]
      end
      
      protected
      
      def self.do_descendents clazz, class_with_consts, visited
        result = [clazz]
        visited << class_with_consts.name
        class_with_consts.constants.each do |const| 
          next if const == clazz.name or visited.include?(const)
          clazz2 = class_with_consts.class_eval "#{const}"
          next unless clazz2.respond_to?(:ancestors)
          result += [clazz2] if clazz2.ancestors.include? clazz
          result += do_descendents(clazz, clazz2, visited) unless visited.include?(clazz2.name)
        end
        result.flatten.uniq
      end
    end
  end
end