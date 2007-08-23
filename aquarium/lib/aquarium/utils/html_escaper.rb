module Aquarium
  module Utils
    module HtmlEscaper
      def self.escape message
        do_escape message
      end
      def escape message
        HtmlEscaper.do_escape message
      end
  
      private
      def self.do_escape message
        message.gsub(/\</, "&lt;").gsub(/\>/, "&gt;")
      end
    end
  end
end
