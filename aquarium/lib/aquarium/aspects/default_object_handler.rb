module Aquarium
  module Aspects
    # Some classes and modules support a :default_object flag and use it if no type or
    # object is specified. For "convenience", requires that classes and modules including
    # this module have a hash @specification defined with keys :default_object, :types,
    # and :objects.
    module DefaultObjectHandler
      def default_object_given
        @specification[:default_object]
      end

      def default_object_given?
        not (default_object_given.nil? or default_object_given.empty?)
      end
      
      def use_default_object_if_defined
        return unless default_object_given?
        object = default_object_given.to_a.first  # there will be only one...
        if (object.kind_of?(Class) || object.kind_of?(Module))
          @specification[:types] = default_object_given
        else
          @specification[:objects] = default_object_given
        end
      end
    end
  end
end
