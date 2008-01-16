module Aquarium
  module Utils
    module TypeUtils
      def self.is_type? type_or_object
        type_or_object.kind_of?(Class) or type_or_object.kind_of?(Module)
      end

      def self.descendents clazz
        visited_types = ["Class", "Module", "Object", clazz]
        do_descendents clazz, Class, visited_types
      end
      
      protected
      
      def self.do_descendents clazz, class_with_consts, visited
        result = [clazz]
        visited << class_with_consts
          # p "#{clazz}, #{class_with_consts}: #{class_with_consts.constants.inspect .gsub(/\</,"&lt;").gsub(/\>/,"&gt;")}<br/>"
        class_with_consts.constants.each do |const| 
          next if const == clazz.name 
          clazz2 = class_with_consts.class_eval "#{const}"
          next if visited.include?(clazz2) or not clazz2.respond_to?(:ancestors)
          visited << clazz2
          result += [clazz2] if clazz2.ancestors.include? clazz
          result += do_descendents(clazz, clazz2, visited) 
        end
        result.flatten.uniq
      end
    end
  end
end