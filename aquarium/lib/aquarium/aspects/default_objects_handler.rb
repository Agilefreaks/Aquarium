require 'aquarium/utils/array_utils'
require 'set'

module Aquarium
  module Aspects
    # Some classes support a <tt>:default_objects</tt> option and use it if no type or
    # object is specified. In other words, the <tt>:default_objects</tt> option is ignored
    # if  <tt>:types</tt> or <tt>:objects</tt> is present.
    # This module handles this behavior for all the classes that include it. These classes 
    # are assumed to have <tt>@specification</tt> defined with keys 
    # <tt>:default_objects</tt>, <tt>:types</tt>, and <tt>:objects</tt>.
    module DefaultObjectsHandler
      include Aquarium::Utils::ArrayUtils
      
      def default_objects_given
        if @default_objects.nil?
          ary1 = make_array(@specification[:default_objects])
          ary2 = make_array(@specification[:default_object])
          @default_objects = ary1 + ary2
        end
        @default_objects
      end

      def default_objects_given?
        not default_objects_given.empty?
      end
      
      def use_default_objects_if_defined
        return unless default_objects_given?
        default_objects_given.each do |object|
          if (object.kind_of?(Class) || object.kind_of?(Module))
            @specification[:types] ||= []
            @specification[:types] << object
          else
            @specification[:objects] ||= []
            @specification[:objects] << object
          end
        end
      end
    end
  end
end
