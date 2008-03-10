require 'logger'
require 'aquarium/utils/default_logger'

module Aquarium
  module Utils

    # Support parsing and processing of key-value pairs of options, where the values are always converted
    # to sets.
    # Types including this module should have their <tt>initialize</tt> methods call this module's
    #   <tt>init_specification</tt> to do the options processing.
    # Including types may define the following method:
    #   <tt>init_type_specific_specification(original_options, options_hash)</tt>
    # If defined, it is called to perform any final options handling unique for the type 
    # (see Pointcut for an example).
    #
    # Several class methods are included in including types for defining convenience instance methods.
    # for options +:foo+ and +:bar+, calling:
    #   <tt>canonical_options_given_methods :foo, :bar</tt>
    # will define several methods for each option specified, e.g.,:
    #   <tt>foo_given? # => returns true if a value was specified for the :foo option</tt>
    #   <tt>foo_given  # => returns the value of @specification[:foo]</tt>
    #   <tt>bar_given? # etc.
    #   <tt>bar_given
    # If you would like corresponding reader and writer methods, pass a list of the keys for which you want these
    # methods defined to
    #   <tt>canonical_option_reader   :foo, :bar   # analogous to attr_reader
    #   <tt>canonical_option_writer   :foo, :bar   # analogous to attr_writer
    #   <tt>canonical_option_accessor :foo, :bar   # analogous to attr_accessor
    # For all of these methods, you can also pass CANONICAL_OPTIONS (discussed below) to define methods
    # for all of the "canonical" options. _E.g.,_
    #   <tt>canonical_option_accessor CANONICAL_OPTIONS
    #
    # These methods are not defined by default to prevent accidentally overriding other methods that you might
    # have defined with the same names. Also, note that the writer methods will convert the inputs to sets,
    # following the conventions for the options and the readers will return the sets. If you want different handling,
    # you'll have to provide custom implementations. Note that special-case accessor methods are already defined 
    # for the :noop and :logger options (discussed below) where the writers expect single values, not sets, and the
    # readers return the single values.
    # Finally, these +canonical_option_*+ methods should only be called with the *keys* for the +CANONICAL_OPTIONS+.
    # The keys are considered the "canonical options", while the values for the keys are synonyms that can be used instead.
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
      include SetUtils
      include ArrayUtils
      
      def self.universal_options
        [:logger_stream, :logger, :severity, :noop]
      end

      attr_reader :specification
      
      # Todo: Replace this with an aspect advising initialize?
      # Todo: Intead of calling an :init_type_specific_specification, just use the block argument!!
      def init_specification options, canonical_options, additional_allowed_options = [], &optional_block
        @canonical_options = canonical_options
        @additional_allowed_options = additional_allowed_options.map{|x| x.respond_to?(:intern) ? x.intern : x}
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
          @specification[key.intern] = Set.new(all_related_options.flatten)
        end
        
        OptionsUtils::universal_options.each do |uopt| 
          @specification[uopt] = Set.new(make_array(options_hash[uopt])) unless options_hash[uopt].nil? 
        end
        @specification[:noop] ||= Set.new([false])
        set_logger_if_stream_specified     
        set_logger_severity_if_specified   
        set_default_logger_if_not_specified 
        
        if respond_to? :init_type_specific_specification
          init_type_specific_specification @original_options, options_hash, &optional_block
        end
        validate_options options_hash
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
  
      [:logger, :noop].each do |name|
        module_eval(<<-EOF, __FILE__, __LINE__)
          def #{name}
            @specification[:#{name}].kind_of?(Set) ? @specification[:#{name}].to_a.first : @specification[:#{name}]
          end
          def #{name}= value
            @specification[:#{name}] = make_set(make_array(value))
          end
        EOF
      end
    
      module ClassMethods
        def canonical_option_reader *canonical_option_key_list
          return if canonical_option_key_list.nil? or canonical_option_key_list.empty?
          keys = determine_options_for_accessors canonical_option_key_list
          keys.each do |name|
            define_method(name) do 
              @specification[name]
            end
          end
        end
        def canonical_option_writer *canonical_option_key_list
          return if canonical_option_key_list.nil? or canonical_option_key_list.empty?
          keys = determine_options_for_accessors canonical_option_key_list
          keys.each do |name|
            define_method("#{name}=") do |value|
              @specification[name] = make_set(make_array(value))
            end
          end
        end
        def canonical_option_accessor *canonical_option_key_list
          canonical_option_reader *canonical_option_key_list
          canonical_option_writer *canonical_option_key_list
        end
      
        def canonical_options_given_methods canonical_options
          keys = canonical_options.respond_to?(:keys) ? canonical_options.keys : canonical_options 
          (keys + OptionsUtils::universal_options).each do |name|
            module_eval(<<-EOF, __FILE__, __LINE__)
              def #{name}_given
                @specification[:#{name}]
              end
  
              def #{name}_given?
                not (#{name}_given.nil? or #{name}_given.empty?)
              end
            EOF
          end
        end

        protected
        def determine_options_for_accessors canonical_option_key_list
          keys = canonical_option_key_list
          if canonical_option_key_list.kind_of?(Array) and canonical_option_key_list.size == 1
            keys = canonical_option_key_list[0]
          end
          if keys.respond_to? :keys
            keys = keys.keys
          end
          keys
        end
      end
      
      def self.append_features clazz
        super
        ClassMethods.send :append_features, (class << clazz; self; end)
      end
  
      protected
    
      def all_allowed_option_symbols
        @canonical_options.to_a.flatten.map {|o| o.intern} + @additional_allowed_options
      end
      
      # While it's tempting to use the #logger_stream_given?, etc. methods, they will only exist if the
      # including class called canonical_options_given_methods!
      def set_logger_if_stream_specified 
        return if @specification[:logger_stream].nil? or @specification[:logger_stream].empty?
        self.logger = Logger.new @specification[:logger_stream].to_a.first
        self.logger.level = DefaultLogger::DEFAULT_SEVERITY_LEVEL
      end
    
      def set_logger_severity_if_specified 
        return if @specification[:severity].nil? or @specification[:severity].empty?
        if self.logger.nil?
          self.logger = Logger.new STDERR
        end
        self.logger.level = @specification[:severity].to_a.first
      end
    
      def set_default_logger_if_not_specified 
        self.logger ||= DefaultLogger.logger
      end
    end
  end
end