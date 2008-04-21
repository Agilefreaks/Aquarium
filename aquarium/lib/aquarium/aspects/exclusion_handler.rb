require 'aquarium/utils/set_utils'

module Aquarium
  module Aspects
    
    # Defines methods shared by several classes that take <tt>:exclude_*</tt> arguments.
    module ExclusionHandler
      include Aquarium::Utils::HashUtils
      
      def join_point_excluded? jp
        is_excluded_pointcut?(jp) or is_excluded_join_point?(jp) or is_excluded_type_or_object?(jp.type_or_object) or is_excluded_method?(jp.method_name)
      end
      
      def is_excluded_pointcut? jp
        return false if all_excluded_pointcuts.empty?
        all_excluded_pointcuts.find do |pc|
          pc.join_points_matched.find do |jp2|
            jp2 == jp || jp2.eql?(jp)
          end
        end
      end
      
      def set_calculated_excluded_pointcuts excluded_pointcuts
        @calculated_excluded_pointcuts = excluded_pointcuts
        @all_excluded_pointcuts = @specification[:exclude_pointcuts] | Set.new(@calculated_excluded_pointcuts)
      end
      
      def all_excluded_pointcuts
        @all_excluded_pointcuts ||= @specification[:exclude_pointcuts]
      end        

      # Using @specification[:exclude_join_points].include?(jp) doesn't always work correctly (it probably uses equal?())!
      def is_excluded_join_point? jp
        return false if @specification[:exclude_join_points].nil?
        @specification[:exclude_join_points].find {|jp2| jp2 == jp || jp2.eql?(jp)}
      end

      def is_excluded_type_or_object? type_or_object
        unless @specification[:exclude_objects].nil?
          return true if @specification[:exclude_objects].include?(type_or_object)
        end
        unless @specification[:exclude_types_calculated].nil?
          return true if @specification[:exclude_types_calculated].find do |t|
            case t
            when String: type_or_object.name.eql?(t)
            when Symbol: type_or_object.name.eql?(t.to_s)
            when Regexp: type_or_object.name =~ t
            else type_or_object == t
            end
          end
        end
        false
      end
 
      def is_excluded_method? method
        is_explicitly_excluded_method?(method) or matches_excluded_method_regex?(method)
      end

      def is_explicitly_excluded_method? method
        return false if @specification[:exclude_methods].nil?
        @specification[:exclude_methods].include? method
      end

      def matches_excluded_method_regex? method
        return false if @specification[:exclude_methods].nil?
        regexs = @specification[:exclude_methods].find_all {|s| s.kind_of? Regexp}
        return false if regexs.empty?
        regexs.find {|re| method.to_s =~ re}          
      end
      
    end
  end
end
