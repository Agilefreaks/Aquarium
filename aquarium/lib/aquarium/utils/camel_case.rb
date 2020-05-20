module Aquarium
  module Utils
    module CamelCase
      def to_camel_case str
        str.split('_').map {|s| s[0,1]=s[0,1].capitalize; s}.join
      end

      def to_snake_case str
        str.gsub(/([A-Z]+[a-z0-9_-]*)/, '\1_').downcase.gsub(/__*/, '_').gsub(/_$/, '').gsub(/^_/, '')
      end
    end
  end
end

# bad id, as at least one other library wants to define from on string
# class String
#   include Aquarium::Extensions::CamelCase
# end