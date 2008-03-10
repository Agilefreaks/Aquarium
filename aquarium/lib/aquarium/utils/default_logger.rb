require 'logger'

module Aquarium
  module Utils
    # DefaultLogger holds the Aquarium-wide "default" Ruby standard library logger.
    # Individual objects may chose to create their own loggers.
    module DefaultLogger
      
      DEFAULT_SEVERITY_LEVEL = Logger::Severity::WARN
      @@default_logger = Logger.new STDERR
      @@default_logger.level = DEFAULT_SEVERITY_LEVEL
      
      def self.logger
        @@default_logger
      end
      
      def self.logger= logger
        @@default_logger = logger
      end
    end
  end
end