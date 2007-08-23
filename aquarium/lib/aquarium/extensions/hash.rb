require 'aquarium/utils/array_utils'

module Aquarium
  module Extensions
    module HashHelper
  
      # Intersection of self with a second hash, which returns a new hash. 
      # If the same key is present in both, but the values are
      # not "==" or "eql?", then the optional block is invoked to compute the intersection
      # of the two values. If no block is given, it is assumed that the two key-value pairs
      # should not be considered overlapping.
      def intersection other_hash
        return {} if other_hash.nil? or other_hash.empty?
        keys2 = Set.new(self.keys).intersection(Set.new(other_hash.keys))
        result = {}
        keys2.each do |key|
          values1 = self[key]
          values2 = other_hash[key]
          if values1 == values2 or values1.eql?(values2)
            result[key] = values1
          else block_given?
            result[key] = yield values1, values2
          end
        end
        result
      end
  
      alias :and :intersection

      # Union of self with a second hash, which returns a new hash. If both hashes have
      # the same key, the value will be the result of evaluating the given block. If no
      # block is given, the result will be same behavior that "merge" provides; the 
      # value in the second hash "wins".
      def union other_hash
        result = {}
        self.each {|key, value| result[key] = value}    
        return result if other_hash.nil? or other_hash.empty?
        other_hash.each do |key, value| 
          if result[key].nil? or ! block_given?
            result[key] = value
          else
            result[key] = yield result[key], value
          end
        end
        result
      end
  
      alias :or :union
  
      # It appears that Hash#== uses Object#== (i.e., self.object_id == other.object_id) when
      # comparing hash keys. (Array#== uses the overridden #== for the elements.)
      def eql_when_keys_compared? other
        return true  if     self.object_id == other.object_id
        return false unless self.class     == other.class
        keys1 = sort_keys(self.keys)
        keys2 = sort_keys(other.keys)
        return false unless keys1.eql?(keys2)
        (0...keys1.size).each do |index|
          # Handle odd cases where eql? and == behavior differently
          return false unless self[keys1[index]].eql?(other[keys2[index]]) || self[keys1[index]] == other[keys2[index]]
        end
        true
      end
  
      def equivalent_key key
        i = keys.index(key)
        i.nil? ? nil : keys[i] 
      end
  
      private
  
      def sort_keys keys
        keys.sort do |x, y|
          x2 = x.respond_to?(:<=>) ? x : x.inspect
          y2 = y.respond_to?(:<=>) ? y : y.inspect
          x2 <=> y2
        end
      end
    end
  end
end

class Hash
  include Aquarium::Extensions::HashHelper
end