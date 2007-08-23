require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/extensions/hash'
require 'aquarium/utils/array_utils'
require 'aquarium/utils/hash_utils'
require 'set'

describe Hash, "#intersection" do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  before(:each) do
    @hash = {:a => 'a', :b => [:b1, :b2], :c => 'c'}
  end
  
  it "should return the same hash if intersected with itself." do
    @hash.intersection(@hash).should == @hash
  end 

  it "should return the same hash if intersected with an equivalent hash." do
    @hash.intersection({:a => 'a', :b => [:b1, :b2], :c => 'c'}).should == @hash
  end 

  it "should return an empty hash if one of the input hashes is empty." do
    {}.intersection(@hash).should == {}
  end 

  it "should return the common subset hash for two, non-equivalent hashes." do
    hash2 = {:b =>:b1, :c => 'c', :d => 'd'}
    @hash.intersection(hash2){|values1, values2| Set.new(make_array(values1)).intersection(Set.new(make_array(values2)))}.should == {:b =>Set.new([:b1]), :c => 'c'}
  end 
end

describe "intersection of hashes", :shared => true do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  before(:each) do
    @hash = {:a => 'a', :b => [:b1, :b2], :c => 'c'}
  end
  
  it "should return the same hash if intersected with itself." do
    @hash.intersection(@hash).should == @hash
  end 

  it "should return the same hash if intersected with an equivalent hash." do
    @hash.intersection({:a => 'a', :b => [:b1, :b2], :c => 'c'}).should == @hash
  end 

  it "should return an empty hash if one of the input hashes is empty." do
    {}.intersection(@hash).should == {}
  end 

  it "should return the common subset hash for two, non-equivalent hashes." do
    hash2 = {:b =>:b1, :c => 'c', :d => 'd'}
    @hash.intersection(hash2){|value1, value2| Set.new(make_array(value1)).intersection(Set.new(make_array(value2)))}.should == {:b =>Set.new([:b1]), :c => 'c'}
  end 
end

describe Hash, "#intersection" do
  it_should_behave_like "intersection of hashes"
end

describe Hash, "#and" do
  it_should_behave_like "intersection of hashes"
end

describe "union of hashes", :shared => true do
  include Aquarium::Utils::ArrayUtils
  include Aquarium::Utils::HashUtils

  before(:each) do
    @hash = {:a => 'a', :b => [:b1, :b2], :c => 'c'}
  end
  
  it "should return the same hash if unioned with itself." do
    @hash.union(@hash).should == @hash
  end 

  it "should return the same hash if unioned with an equivalent hash." do
    @hash.union({:a => 'a', :b => [:b1, :b2], :c => 'c'}).should == @hash
  end 

  it "should return a hash that is equivalent to the non-empty hash if the other hash is empty." do
    {}.union(@hash).should == @hash
    @hash.union({}).should == @hash
  end 

  it "should return the same hash if unioned with nil." do
    @hash.union(nil).should == @hash
  end 

  it "should return a hash equivalent to the output of Hash#merge for two, non-equivalent hashes, with no block given." do
    hash2 = {:b =>:b3, :c => 'c2', :d => 'd'}
    @hash.union(hash2).should == {:a => 'a', :b => :b3, :c => 'c2', :d => 'd'}
  end 

  it "should return the combined hashes for two, non-equivalent hashes, with a block given to merge values into an array." do
    hash2 = {:b =>:b3, :c => 'c2', :d => 'd'}
    @hash.union(hash2){|value1, value2| Set.new(make_array(value1)).union(Set.new(make_array(value2)))}.should == {:a => 'a', :b => Set.new([:b1, :b2, :b3]), :c => Set.new(['c', 'c2']), :d => 'd'}
  end 
end

describe Hash, "#union" do
  it_should_behave_like "union of hashes"
end

describe Hash, "#or" do
  it_should_behave_like "union of hashes"
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
