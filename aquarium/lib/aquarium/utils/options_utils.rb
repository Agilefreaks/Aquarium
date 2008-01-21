module Aquarium
  module Utils

    # Support parsing and processing of key-value pairs of options.
    # Including types must define the following methods (see Pointcut for an example):
    #   canonical_options  # Return the hash of canonical options
    #   all_allowed_option_symbols # Returns an array of all allowed options as symbols.
    #   init_type_specific_specification(original_options, options_hash) for any unique options handling (optional).
    module OptionsUtils
      
      def self.universal_options
        [:verbose, :log, :noop]
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
        uopts = {
          :log     => options_hash[:log] || "",
          :verbose => options_hash[:verbose] || 0,
          :noop    => options_hash[:noop] || false
        }
        OptionsUtils::universal_options.each { |uopt| @specification[uopt] = Set.new [uopts[uopt]] }
        init_type_specific_specification @original_options, options_hash, &optional_block
        validate_options options_hash
      end
      
      OptionsUtils::universal_options.each do |name|
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
      def init_type_specific_specification options, &optional_block
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
  
    end
  end
end