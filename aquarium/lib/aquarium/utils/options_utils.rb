require 'logger'
require 'aquarium/utils/default_logger'

module Aquarium
  module Utils

    # == OptionsUtils
    # Support parsing and processing of key-value pairs of options, where the values are always converted
    # to Sets.
    # Types including this module should have their <tt>initialize</tt> methods call this module's
    # #init_specification to do the options processing. See its documentation for more details.
    #
    # Several <i>class</i> methods are included for defining convenience <i>instance</i> methods.
    # For example, for options <tt>:foo</tt> and <tt>:bar</tt>, calling:
    #
    #   canonical_options_given_methods :foo, :bar
    #
    # will define several methods for each option specified, e.g.,:
    #
    #   foo_given    # => returns the value of @specification[:foo]
    #   foo_given?   # => returns true "foo_given" is not nil or empty.
    #   bar_given    # etc...
    #   bar_given?
    #
    # If you would like corresponding reader and writer methods, pass a list of the keys for which you want these
    # methods defined to one of the following methods:
    #
    #   canonical_option_reader   :foo, :bar   # analogous to attr_reader
    #   canonical_option_writer   :foo, :bar   # analogous to attr_writer
    #   canonical_option_accessor :foo, :bar   # analogous to attr_accessor
    #
    # For all of these methods, you can also pass <tt>CANONICAL_OPTIONS</tt> (discussed below) to define methods
    # for all of the "canonical" options, <i>e.g.,</i>
    #
    #   canonical_option_accessor CANONICAL_OPTIONS
    #
    # These methods are not defined by default to prevent accidentally overriding other methods that you might
    # have defined with the same names. Also, note that the writer methods will convert the inputs to sets,
    # following the conventions for the options and the readers will return the sets. If you want different handling,
    # you'll have to provide custom implementations. 
    #
    # Note that special-case accessor methods are already defined for the <tt>:noop</tt> and <tt>:logger</tt>
    # options (discussed below) where the writers expect single values, not sets, and the
    # readers return the single values. (Yea, it's a bit inconsistent...)
    #
    # Finally, these <tt>canonical_option_*</tt> methods should only be called with the *keys* for the +CANONICAL_OPTIONS+.
    # The keys are considered the "canonical options", while the values for the keys are synonyms that can be used instead.
    #
    # This module also defines several universal options that will be available to all types that include this module:
    # <tt>:logger</tt>::
    #   A Ruby standard library Logger used for any messages. A default system-wide logger is used otherwise.
    #   The corresponding <tt>logger</tt> and <tt>logger=</tt> accessors are defined.
    #
    # <tt>:logger_stream</tt>::
    #   An an alternative to defining the logger, you can define just the output stream where log output will be written.
    #   If this option is specified, a new logger will be created for the instance with this output stream.
    #   There are no corresponding accessors; use the appropriate methods on the <tt>logger</tt> object instead.
    #
    # <tt>:severity</tt>::
    #   The logging severity level, one of the Logger::Severity values or a corresponding integer value.
    #   If this option is specified, a new logger will be created for the instance with this output stream.
    #   There are no corresponding accessors; use the corresponding methods on the <tt>logger</tt> object instead.
    #
    # <tt>:noop => options_hash[:noop] || false</tt>::
    #   If true, don't do "anything", the interpretation of which will vary with the type receiving the option.
    #   For example, a type might go through some initialization, such as parsng its options, but
    #   do nothing after that. Primarily useful for debugging and testing.    
    #   The value can be accessed through the <tt>noop</tt> and <tt>noop=</tt> accessors.
    #
    module OptionsUtils
      include SetUtils
      include ArrayUtils
      
      def self.universal_options
        [:logger_stream, :logger, :severity, :noop]
      end
      
      def self.universal_prepositions
        [:for, :on, :in, :within]
      end

      attr_reader :specification

      # Class #initialize methods call this method to process the input options.
      # Pass an optional block to the method that takes no parameters if you want 
      # to do additional processing of the options before init_specification validates 
      # the options. The block will have access to the @specification hash built up by
      # init_specification and to a new attribute @original_options, which will be a 
      # copy of the original options passed to init_specification (it will be either a 
      # hash or an array). 
      # Finally, if the block returns a value or an array of values, they will be 
      # treated as keys to ignore in the options when they are validated. This is a 
      # way of dynamically treating an option as valid that can't be known in advance.
      # (See Aspect and Pointcut for examples of this feature in use.)
      def init_specification options, canonical_options, additional_allowed_options = []
        @canonical_options = canonical_options
        @additional_allowed_options = additional_allowed_options.map{|x| x.respond_to?(:intern) ? x.intern : x}
        @original_options = options.nil? ? {} : options.dup 
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
        
        ignorables = yield if block_given?
        ignorables = [] if ignorables.nil? 
        ignorables = [ignorables] unless ignorables.kind_of? Array
        validate_options(options_hash.reject {|k,v| ignorables.include?(k)})
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

        # Service method that adds a new canonical option and corresponding array with 
        # "exclude_" prepended to all values. The new options are added to the input hash.
        def add_exclude_options_for option, options_hash
          all_variants = options_hash[option].dup
          options_hash["exclude_#{option}"] = all_variants.map {|x| "exclude_#{x}"}
        end

        # Service method that adds a new canonical option and corresponding array with 
        # "preposition" prefixes, e.g., "on_", "for_", etc. prepended to all values. 
        # The new options are added to the input hash.
        def add_prepositional_option_variants_for option, options_hash
          all_variants = options_hash[option].dup + [option]
          OptionsUtils.universal_prepositions.each do |prefix|
            all_variants.each do |variant|
              options_hash[option] << "#{prefix}_#{variant}" 
            end
          end
        end

        private
        
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
  
      private
    
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