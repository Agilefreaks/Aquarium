require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_types'
require 'aquarium/extensions/hash'
require 'aquarium/utils/array_utils'
require 'aquarium/utils/hash_utils'
require 'set'
  
class CC
  include Comparable
  def initialize i
    @value = i
  end
  attr_reader :value
  def == other
    value == other.value
  end
  def <=>
    value <=> other.value
  end
end

def before_hash_spec
  @c1 = CC.new(1)
  @c2 = CC.new(2)
  @c3 = CC.new(3)
  @cc1 = [@c1, @c2]
  @cc2 = [@c2, @c3]
  @hash = {:a => ['a1'], :b => [:b1, :b2], :c => @cc1}
end

describe "intersection of hashes", :shared => true do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  before(:each) do
    before_hash_spec
  end
  
  it "should return the same hash if intersected with itself." do
    @hash.and(@hash).should == @hash
  end 

  it "should return the same hash if intersected with an equivalent hash." do
    @hash.and({:a => ['a1'], :b => [:b1, :b2], :c => @cc1}).should == @hash
  end 

  it "should return an empty hash if one of the input hashes is empty." do
    {}.and(@hash).should == {}
  end 

  it "should return the common subset hash for two, if the values respond to #&." do
    hash2 = {:b => [:b1], :c => @cc2, :d => ['d']}
    @hash.and(hash2).should == {:b => [:b1], :c => [@c2]}
  end 

  it "should return the common subset of hash values for partially-overlapping keys as specified by a given block." do
    hash2 = {:b =>:b1, :c => @cc2, :d => 'd'}
    @hash.and(hash2){|value1, value2| Set.new(make_array(value1)).intersection(Set.new(make_array(value2)))}.should == {:b => Set.new([:b1]), :c => Set.new([@c2])}
  end
end

describe Hash, "#intersection" do
  it_should_behave_like "intersection of hashes"
end

describe Hash, "#and" do
  it_should_behave_like "intersection of hashes"
end

describe Hash, "#&" do
  it_should_behave_like "intersection of hashes"
  
  it "should support operator-style semantics" do
    ({:a => ['a1', 'a2'], :c => @cc1} & {:a => ['a1'], :b => [:b1, :b2], :c => @cc2}).should == {:a => ['a1'], :c => [@c2]}
  end
end

describe "union of hashes", :shared => true do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  before(:each) do
    before_hash_spec
  end
  
  it "should return the same hash if unioned with itself." do
    @hash.union(@hash).should == @hash
  end 

  it "should return the same hash if unioned with an equivalent hash." do
    @hash.union({:a => ['a1'], :b => [:b1, :b2], :c => @cc1}).should == @hash
  end 

  it "should return a hash that is equivalent to the non-empty hash if the other hash is empty." do
    {}.union(@hash).should == @hash
    @hash.union({}).should == @hash
  end 

  it "should return the same hash if unioned with nil." do
    @hash.union(nil).should == @hash
  end 

  it "should return the combined hash value, if the values respond to #|." do
    hash2 = {:b => [:b3], :c => @cc2, :d => ['d']}
    @hash.union(hash2).should == {:a => ['a1'], :b => [:b1, :b2, :b3], :c => [@c1, @c2, @c3], :d => ['d']}
  end 

  it "should return a hash equivalent to the output of Hash#merge for two, non-equivalent hashes, with no block given and values don't respond to #|." do
    hash2 = {:b => :b3, :c => @cc2, :d => 'd'}
    @hash.union(hash2).should == {:a => ['a1'], :b => :b3, :c => [@c1, @c2, @c3], :d => 'd'}
  end 

  it "should return the combined hash values as specified by a given block." do
    hash2 = {:b => :b3, :c => @cc2, :d => 'd'}
    @hash.union(hash2){|value1, value2| Set.new(make_array(value1)).union(Set.new(make_array(value2)))}.should == {:a => Set.new(['a1']), :b => Set.new([:b1, :b2, :b3]), :c => Set.new([@c1, @c2, @c3]), :d => Set.new(['d'])}
  end 
end

describe Hash, "#union" do
  it_should_behave_like "union of hashes"
end

describe Hash, "#or" do
  it_should_behave_like "union of hashes"
end  

describe Hash, "#|" do
  it_should_behave_like "union of hashes"
  
  it "should support operator-style semantics" do
    ({:a => ['a1'], :d => ['d']} | {:a => ['a2'], :b => [:b1, :b2], :c => @cc2}).should == {:a => ['a1', 'a2'], :b => [:b1, :b2], :c => @cc2, :d => ['d']}
  end
end


describe "subtraction of hashes", :shared => true do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils
  
  before(:each) do
    before_hash_spec
    # override value:
    @hash = {:a => ['a1', 'a2'], :b => [:b1, :b2], :c => @cc1}
  end
  
  it "should return an empty hash if subtracted from itself." do
    (@hash - @hash).should be_empty
  end 

  it "should return an empty hash if an equivalent hash is subtracted from it." do
    (@hash - {:a => ['a1', 'a2'], :b => [:b1, :b2], :c => @cc1}).should be_empty
  end 

  it "should return an equivalent hash if the second hash is empty." do
    (@hash - {}).should == @hash
  end 

  it "should return an equivalent hash if the second hash is nil." do
    (@hash - nil).should == @hash
  end 
  
  it "should return an empty hash if the first hash is empty, independent of the second hash." do
    ({} - @hash).should be_empty
  end 

  it "should return a hash with all keys in the second hash removed, independent of the corresponding values, if no block is given." do
    hash2 = {:b =>:b3, :c => 'c', :d => 'd'}
    (@hash - hash2).should == {:a => ['a1', 'a2']}
  end 

  it "should return a hash with the values subtraced for partially-overlapping keys as specified by a given block." do
    hash2 = {:b =>:b2, :c => @cc2, :d => 'd'}
    @hash.minus(hash2) do |value1, value2| 
      Set.new(make_array(value1)) - Set.new(make_array(value2))
    end.should == {:a => Set.new(['a1', 'a2']), :b => Set.new([:b1]), :c => Set.new([@c1])}
  end 

  it "should be not associative." do
    hash1 = {:a => :a1, :b =>:b1, :c => :c1, :d => :d1}
    hash2 = {:b =>:b3, :c => 'c'}
    hash3 = {:a =>:a4, :c => 'c'}
    ((hash1 - hash2) - hash3).should == {:d => :d1}
    (hash1 - (hash2 - hash3)).should == {:a => :a1, :c => :c1, :d => :d1}
  end 
end

describe Hash, "#minus" do
  it_should_behave_like "subtraction of hashes"
end

describe Hash, "#-" do
  it_should_behave_like "subtraction of hashes"

  it "should support operator-style semantics" do
    hash1 = {:a => :a1, :b =>:b1, :c => :c1, :d => :d1}
    hash2 = {:b =>:b3, :c => 'c'}
    hash3 = {:a =>:a4, :c => 'c'}
    ((hash1 - hash2) - hash3).should == {:d => :d1}
    (hash1 - (hash2 - hash3)).should == {:a => :a1, :c => :c1, :d => :d1}
  end 
end

describe Hash, "#eql_when_keys_compared?" do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  it "should return true when comparing a hash to itself." do
    h1={"1" => :a1, "2" => :a2, "3" => :a3}
    h1.eql_when_keys_compared?(h1).should == true
  end

  it "should return true for hashes with string keys that satisfy String#==." do
    h1={"1" => :a1, "2" => :a2, "3" => :a3}
    h2={"1" => :a1, "2" => :a2, "3" => :a3}
    h1.eql_when_keys_compared?(h2).should == true
  end

  it "should return false for hashes with matching keys, but different values." do
    h1={"1" => :a1, "2" => :a2, "3" => /a/}
    h2={"1" => :a1, "2" => :a2, "3" => /b/}
    h1.eql_when_keys_compared?(h2).should == false
  end

  it "should return false for hashes where one hash is a subset of the other." do
    h1={"1" => :a1, "2" => :a2}
    h2={"1" => :a1, "2" => :a2, "3" => :a3}
    h1.eql_when_keys_compared?(h2).should == false
    h2.eql_when_keys_compared?(h1).should == false
  end
  
  it "should return true for hashes with Object keys that define a #<=> method, while Hash#eql? would return false." do
    class Key
      def initialize key
        @key = key
      end
      attr_reader :key
      def eql? other
        key.eql? other.key
      end
      def <=> other
        key <=> other.key
      end
    end
    
    h1 = {}; h2 = {}
    (0...4).each do |index|
      h1[Key.new(index)] = {index.to_s => [index, index+1]}
      h2[Key.new(index)] = {index.to_s => [index, index+1]}
    end
    h1.eql_when_keys_compared?(h2).should == true
    h1.eql?(h2).should == false
  end
end

describe Hash, "#equivalent_key" do
  it "should return the key in the hash for which input_value#==(key) is true." do
    class Key
      def initialize key
        @key = key
      end
      attr_reader :key
      def eql? other
        key.eql? other.key
      end
      alias :== :eql?
    end
    
    h1 = {}; h2 = {}
    (0...4).each do |index|
      h1[Key.new(index)] = {index.to_s => [index, index+1]}
      h2[Key.new(index)] = {index.to_s => [index, index+1]}
    end
    h1[Key.new(0)].should be_nil
    h1.equivalent_key(Key.new(0)).should_not be_nil
    h1.equivalent_key(Key.new(5)).should     be_nil
  end
  
end
