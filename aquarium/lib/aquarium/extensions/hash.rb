require 'aquarium/utils/array_utils'

module Aquarium
  module Extensions
    module HashHelper
  
      def and other_hash
        return {} if other_hash.nil? or other_hash.empty?
        keys2 = Set.new(self.keys).intersection(Set.new(other_hash.keys))
        result = {}
        keys2.each do |key|
          value1 = self[key]
          value2 = other_hash[key]
          if value1 == value2 or value1.eql?(value2)
            result[key] = value1
          elsif block_given?
            result[key] = yield value1, value2
          elsif value1.class == value2.class && value1.respond_to?(:&)
            result[key] = (value1 & value2)
          end
        end
        result
      end
  
      alias :intersection :and 
      alias :& :and 

      # Union of self with a second hash, which returns a new hash. It's different from
      # Hash#merge in that it attempts to merge non-equivalent values for the same key,
      # if they are of the same type and respond to #| or a block is given that merges the
      # two values. Otherwise, it behaves like Hash#merge.
      def or other_hash
        return self if other_hash.nil?
        result = {}
        new_keys = self.keys | other_hash.keys
        new_keys.each do |key|
          value1 = self[key]
          value2 = other_hash[key]
          if value1.nil? and not value2.nil?
            result[key] = value2
          elsif (not value1.nil?) and value2.nil?
            result[key] = value1
          elsif value1 == value2 or value1.eql?(value2)
            result[key] = value1 
          elsif block_given?
            result[key] = yield value1, value2
          elsif value1.class == value2.class && value1.respond_to?(:|)
            result[key] = value1 | value2
          else  # Hash#merge behavior
            result[key] = value2
          end
        end
        result
      end
      
      alias :union :or
      alias :| :or
  
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