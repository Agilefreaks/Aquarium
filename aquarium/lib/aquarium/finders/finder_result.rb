require 'aquarium/utils'
require 'aquarium/extensions'

module Aquarium
  module Finders
    # == FinderResult
    # Wraps hashes that hold the results of various *Finder utilities. The #not_matched method returns specified
    # inputs that did not result in a successful find.
    class FinderResult
      include Aquarium::Utils::HashUtils
      include Aquarium::Utils::SetUtils
  
      attr_accessor :not_matched, :matched

      def convert_hash_values_to_sets hash
        h = {}
        hash.each do |key, value|
          if value.is_a? Set
            h[key] = value
          elsif value.is_a? Array
            h[key] = Set.new value
          else
            h[key] = Set.new([value])
          end
        end
        h
      end
  
      private :convert_hash_values_to_sets
  
      def initialize hash = {}
        @matched = convert_hash_values_to_sets(hash.reject {|key, value| key.eql?(:not_matched)})
        @not_matched = convert_hash_values_to_sets(make_hash(hash[:not_matched]) {|x| Set.new} || {})
      end
  
      NIL_OBJECT = FinderResult.new unless const_defined?(:NIL_OBJECT)
  
      # Convenience method to get the keys for the matches.
      def matched_keys
        @matched.keys
      end    
  
      # Convenience method to get the keys for the items that did not result in matches.
      def not_matched_keys
        @not_matched.keys
      end    
  
      def << other_result
        append_matched     other_result.matched
        append_not_matched other_result.not_matched
        self
      end
  
      # "Or" two results together
      #--
      # We use dup here and in other methods, rather than FinderResult.new, so that new subclass
      # objects are returned correctly!
      #++
      def or other_result
        result = dup
        result.matched     = hash_union(matched,     other_result.matched)
        result.not_matched = hash_union(not_matched, other_result.not_matched)
        result
      end
  
      alias :union :or
      alias :| :or
  
      # "And" two results together
      def and other_result
        result = dup
        result.matched     = hash_intersection(matched,     other_result.matched)
        result.not_matched = hash_intersection(not_matched, other_result.not_matched)
        result
      end
  
      alias :intersection :and
      alias :& :and
  
      def minus other_result
        result = dup
        result.matched     = matched     - other_result.matched
        result.not_matched = not_matched - other_result.not_matched
        result
      end
      
      alias :- :minus

      def append_matched other_hash = {}
        @matched = convert_hash_values_to_sets hash_union(matched, other_hash)
      end
  
      def append_not_matched other_hash = {}
        @not_matched = convert_hash_values_to_sets hash_union(not_matched, other_hash)
        @not_matched.each_key {|key| purge_matched key}
      end  
  
      def eql? other
        object_id == other.object_id ||
        (matched == other.matched and not_matched == other.not_matched)
      end
  
      alias :== :eql? 
  
      def inspect 
        "FinderResult: {matched: #{matched.inspect}, not_matched: #{not_matched.inspect}}"
      end
  
      alias :to_s :inspect
  
      # Were there no matches?
      def empty?
        matched.empty?
      end
  
      private

      def purge_matched key
        if @matched.keys.include? key
          @not_matched[key] = @not_matched[key].delete_if {|nm| @matched[key].include?(nm)}
        end
      end
  
      def hash_intersection hash1, hash2
        return {} if hash1.nil? or hash2.nil?
        hash1.intersection(hash2) do |value1, value2| 
          make_set(value1) & (make_set(value2))
        end
      end

      def hash_union hash1, hash2
        return hash1 if hash2.nil? or hash2.empty?
        return hash2 if hash1.nil? or hash1.empty?
        hash1.union(hash2) do |value1, value2| 
          make_set(value1) | (make_set(value2))
        end
      end
    end
  end
end
