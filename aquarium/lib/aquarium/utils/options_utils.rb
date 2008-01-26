require 'logger'
require 'aquarium/utils/default_logger'

module Aquarium
  module Utils

    # Support parsing and processing of key-value pairs of options.
    # Types including this module must define the following methods (see Pointcut for an example):
    #   <tt>all_allowed_option_symbols</tt>
    #     Return an array of all allowed options as symbols.
    #   <tt>init_type_specific_specification(original_options, options_hash)</tt>
    #     Called to perform any final options handling unique for the type (optional).
    # In addition, including types should have their <tt>initialize</tt> methods calls this module's
    # <tt>init_specification</tt> to do the options processing.
    #
    # This module also defines several universal options that will be available to all types that include this module:
    # <tt>:logger => options_hash[:logger] || default system-wide Logger</tt>
    #   A standard library Logger used for any messages. A default system-wide logger is used otherwise.
    #   The corresponding <tt>logger</tt> and <tt>logger=</tt> accessors are defined.
    #
    # <tt>:logger_stream => options_hash[:logger_stream]</tt>
    #   An an alternative to defining the logger, you can define just the output stream where log output will be written.
    #   If this option is specified, a new logger will be created for the instance with this output stream.
    #   There is no corresponding accessors; use the corresponding methods on the <tt>logger</tt> object instead.
    #
    # <tt>:severity => options_hash[:severity]</tt>
    #   The logging severity level, one of the Logger::Severity values or the corresponding integer value.
    #   If this option is specified, a new logger will be created for the instance with this output stream.
    #   There is no corresponding accessors; use the corresponding methods on the <tt>logger</tt> object instead.
    #
    # <tt>:noop => options_hash[:noop] || false</tt>
    #   If true, don't do "anything", the interpretation of which will vary with the type receiving the option.
    #   For example, a type might go through some initialization, such as parsng its argument list, but
    #   do nothing after that. Primarily useful for debugging.    
    #   The value can be accessed through the <tt>noop</tt> and <tt>noop=</tt> accessors.
    module OptionsUtils
      
      def self.universal_options
        [:logger_stream, :logger, :severity, :noop]
      end
      
      def init_specification options, canonical_options, &optional_block
        @canonical_options = canonical_options
        @original_options = options.dup unless options.nil?
        @specification = {}
        options ||= {} 
        options_hash = hashify options
        @canonical_options.keys.each do |key|
          all_related_options = make_array(options_hash[key.intern]) || []
          @canonical_options[key].inject(all_related_options) do |ary, o| 
            ary << options_hash[o.intern] if options_hash[o.intern]
            ary
          end
          @specification[key.intern] = Set.new(make_array(all_related_options))
        end

        universal_options = {
          :logger_stream => options_hash[:logger_stream],
          :severity      => options_hash[:severity],
          :noop          => options_hash[:noop] || false
        }

        set_logger_if_logger_or_stream_specified universal_options, options_hash 
        set_logger_severity_if_specified         universal_options, options_hash 
        set_logger_if_not_specified              universal_options, options_hash 
        
        OptionsUtils::universal_options.each do |uopt| 
          @specification[uopt] = Set.new([universal_options[uopt]]) unless universal_options[uopt].nil?
        end
        init_type_specific_specification @original_options, options_hash, &optional_block
        validate_options options_hash
      end
      
      [:logger, :noop].each do |name|
        module_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}
            @specification[:#{name}].to_a.first
          end
          def #{name}= value
            @specification[:#{name}] = Set.new([value])
          end
        EOF
      end
      
      # Override for type-specific initialization
      def init_type_specific_specification original_options, options_hash, &optional_block
      end
      
      def hashify options
        return options if options.kind_of?(Hash)
        new_options = {}
        options.each do |x|
          if x.kind_of?(Hash)
            new_options.merge!(x)
          else
            new_options[x] = Set.new([])
          end
        end
        new_options
      end
      
      def validate_options options
        unknowns = options.keys - all_allowed_option_symbols - OptionsUtils::universal_options
        raise Aquarium::Utils::InvalidOptions.new("Unknown options specified: #{unknowns.inspect}") if unknowns.size > 0
      end
  
      protected
    
      def set_logger_if_logger_or_stream_specified universal_options, options_hash 
        if not options_hash[:logger].nil?
          universal_options[:logger] = options_hash[:logger]
        elsif not options_hash[:logger_stream].nil?
          universal_options[:logger] = Logger.new options_hash[:logger_stream]
        end
      end
    
      def set_logger_severity_if_specified universal_options, options_hash 
        unless options_hash[:severity].nil?
          unless universal_options[:logger].nil?
            universal_options[:logger].level = options_hash[:severity]
          else
            universal_options[:logger] = Logger.new STDERR
            universal_options[:logger].level = options_hash[:severity]
          end
        end
      end
    
      def set_logger_if_not_specified universal_options, options_hash 
        if universal_options[:logger].nil?
          universal_options[:logger] = DefaultLogger.logger
        end 
      end
    
    end
  end
end