require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'

require 'aquarium/finders/finder_result'
require 'aquarium/extensions/set'

describe Aquarium::Finders::FinderResult, "#initialize" do
  before do
    @empty_set = Set.new
  end

  it "should create an empty finder result when no parameters are specified." do
    result = Aquarium::Finders::FinderResult.new
    result.matched.should == {}
    result.not_matched.should == {}
    result.should be_empty
  end
  
  it "should accept a value for the :not_matched parameter and convert it into a hash with the input value as the key and an empty set as the corresponding value" do
    result = Aquarium::Finders::FinderResult.new :not_matched => :b
    result.not_matched.should == {:b => @empty_set}
  end
  
  it "should accept an array for the :not_matched parameter and convert it into a hash with the array values as the keys and empty sets as the corresponding values" do
    result = Aquarium::Finders::FinderResult.new :not_matched => [:a, :b]
    result.not_matched.should == {:a => @empty_set, :b => @empty_set}
  end
  
  it "should accept a hash for the :not_matched parameter and convert the values in the hashd into sets, if necessary." do
    result = Aquarium::Finders::FinderResult.new :not_matched => {:a => 'a', :b => 'b'}
    result.not_matched.should == {:a => Set.new(['a']), :b => Set.new(['b'])}
  end
end  

describe Aquarium::Finders::FinderResult, "#empty?" do
  it "should be true if there are no matches." do
    result = Aquarium::Finders::FinderResult.new
    result.matched.should == {}
    result.not_matched.should == {}
    result.empty?.should be_true
  end

  it "should be true if there are no matches, even if there are not_matched values." do
    result = Aquarium::Finders::FinderResult.new :not_matched => [:a, :b]
    result.matched.should == {}
    empty_set = Set.new
    result.not_matched.should == {:a => empty_set, :b => empty_set}
    result.empty?.should be_true
  end
end

describe Aquarium::Finders::FinderResult, "#not_matched" do
  before do
    @empty_set = Set.new
  end
  
  it "should return an empty hash for a default finder result." do
    Aquarium::Finders::FinderResult.new.not_matched.should == {}
  end

  it "should return an empty hash if all the specified search items matched." do
    result = Aquarium::Finders::FinderResult.new String =>["a", "b"], Hash => {:a => 'a'}
    result.not_matched.should == {}
  end

  it "should return a hash containing as keys the items specified with the :not_matched key in the input hash and empty sets as the corresponding values in the hash." do
    result = Aquarium::Finders::FinderResult.new :not_matched =>[String, Hash]
    result.not_matched.size == 2
    result.not_matched[String].should == @empty_set
    result.not_matched[Hash].should == @empty_set
  end
end

describe Aquarium::Finders::FinderResult, "#not_matched_keys" do
  it "should return an empty array by default." do
    Aquarium::Finders::FinderResult.new.not_matched_keys.should == []
  end

  it "should return an empty array if all the specified search items matched." do
    result = Aquarium::Finders::FinderResult.new String =>["a", "b"], Hash => {:a => 'a'}
    result.not_matched_keys.should == []
  end

  it "should return an array containing the items specified with the :not_matched key in the input hash." do
    result = Aquarium::Finders::FinderResult.new :not_matched =>[String, Hash]
    result.not_matched_keys.size == 2
    result.not_matched_keys.include?(String).should be(true)
    result.not_matched_keys.include?(Hash).should be(true)
  end
end

describe Aquarium::Finders::FinderResult, "#matched" do
  it "should return an empty hash for a new result." do
    Aquarium::Finders::FinderResult.new.matched.should == {}
  end

  it "should return a hash of found search items where the found search items are the keys and arrays of corresponding objects are the corresponding values." do
    result = Aquarium::Finders::FinderResult.new String => ["a", "b"], Hash => {:a => 'a'}
    result.matched.size == 2
    result.matched[String].should == Set.new(["a", "b"])
    result.matched[Hash].should == Set.new([{:a => 'a'}])
  end
end

describe Aquarium::Finders::FinderResult, "#matched_keys" do
  it "should return an empty array by default." do
    Aquarium::Finders::FinderResult.new.matched_keys.should == []
  end

  it "should return an empty array of found search items where the found search items are the keys and arrays of corresponding objects are the corresponding values." do
    result = Aquarium::Finders::FinderResult.new String => ["a", "b"], Hash => {:a => 'a'}
    result.matched_keys.size == 2
    result.matched_keys.include?(String).should be(true)
    result.matched_keys.include?(Hash).should be(true)
  end
end

describe Aquarium::Finders::FinderResult, "#<<" do
  it "should return self." do
    result1 = Aquarium::Finders::FinderResult.new
    result = result1 << Aquarium::Finders::FinderResult.new
    result.object_id.should == result1.object_id
  end
  
  it "should merge the value of the other FinderResult#not_matched into self's not_matched value." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:a => 'a'}
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b'}
    result1 << result2
    result1.not_matched.should == {:a => Set.new(['a']), :b => Set.new(['b'])}
  end

  it "should merge the value of the other FinderResult#matched into self's matched value." do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result1 << result2
    result1.matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
  end
  
  it "should remove not_matched items when the same item is added to matched items from the right-hand side FinderResult." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b3, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result1 << result2
    result1.matched.should     == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
    result1.not_matched.should == {:b => Set.new([:b3]), :c => Set.new([:c1])}
  end    
  
  it "should remove not_matched items when the same item is added to matched items from the right-hand side FinderResult." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b1, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result1 << result2
    result1.matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
    result1.not_matched.should == {:b => Set.new([]), :c => Set.new([:c1])}
  end    
end

describe "union of finder results", :shared => true do
  it "should return a FinderResult equal to the second, non-empty FinderResult if the first FinderResult is empty." do
    result1 = Aquarium::Finders::FinderResult.new
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result = result1.or result2
    result.should be_eql(result2)
  end
  
  it "should return a FinderResult equal to the first, non-empty FinderResult if the second FinderResult is empty." do
    result1 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result2 = Aquarium::Finders::FinderResult.new
    result = result1.or result2
    result.should be_eql(result1)
  end
  
  it "should return a FinderResult that is the union of self and the second FinderResult." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result = result1.or result2
    result.matched.should     == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
    result.not_matched.should == {:b => Set.new(['b']), :c => Set.new(['c'])}
  end    
  
  it "should be unitary." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result = result1.or result2
    result.should be_eql(result1)
    result.should be_eql(result2)
  end    

  it "should be commutative." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result12 = result1.or result2
    result21 = result2.or result1
    result12.should be_eql(result21)
  end    

  it "should be associative." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result3 = Aquarium::Finders::FinderResult.new :c => [:c1, :c2]
    result123a = (result1.or result2).or result3
    result123b = result1.or(result2.or(result3))
    result123a.should be_eql(result123b)
  end    
end

describe Aquarium::Finders::FinderResult, "#union" do
  it_should_behave_like "union of finder results"
end
describe Aquarium::Finders::FinderResult, "#or" do
  it_should_behave_like "union of finder results"
end
describe Aquarium::Finders::FinderResult, "#|" do
  it_should_behave_like "union of finder results"

  it "should support operator-style semantics" do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result3 = Aquarium::Finders::FinderResult.new :c => [:c1, :c2]
    result123a = (result1 | result2) | result3
    result123b = result1 | (result2 | result3)
    result123a.should be_eql(result123b)
  end    
end

describe "intersection of finder results", :shared => true do
  it "should return an empty FinderResult if self is empty." do
    result1 = Aquarium::Finders::FinderResult.new
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result = result1.and result2
    result.should be_eql(result1)
  end
  
  it "should return an empty FinderResult if the second FinderResult is empty." do
    result1 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result2 = Aquarium::Finders::FinderResult.new
    result = result1.and result2
    result.should be_eql(result2)
  end
  
  it "should return an empty FinderResult if there is no overlap between the two FinderResults." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b3, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result = result1.and result2
    result.matched.should     be_empty
    result.not_matched.should be_empty
  end    

  it "should return a FinderResult that is the intersection of self and the second FinderResult." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b1, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => [:b1, :b2]}, :a => [:a1]
    result = result1.and result2
    result.matched.should     == {:a => Set.new([:a1])}
    result.not_matched.should == {:b => Set.new([:b1])}
  end    
  
  it "should be unitary." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result = result1.and result2
    result.should be_eql(result1)
    result.should be_eql(result2)
  end    

  it "should be commutative." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b1, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => [:b1, :b2]}, :a => [:a1]
    result12 = result1.and result2
    result21 = result2.and result1
    result12.should be_eql(result21)
  end    

  it "should be associative." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => :b1, :c => :c1}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :not_matched => {:b => [:b1, :b2]}, :a => [:a1]
    result3 = Aquarium::Finders::FinderResult.new :not_matched => {:b => [:b1]}, :a => [:a1]
    result123a = (result1.and result2).and result3
    result123b = result1.and(result2.and(result3))
    result123a.should be_eql(result123b)
  end    
end

describe Aquarium::Finders::FinderResult, "#intersection" do
  it_should_behave_like "intersection of finder results"
end
describe Aquarium::Finders::FinderResult, "#and" do
  it_should_behave_like "intersection of finder results"
end
describe Aquarium::Finders::FinderResult, "#&" do
  it_should_behave_like "union of finder results"

  it "should support operator-style semantics" do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:b => 'b', :c => 'c'}, :a => [:a1, :a2]
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    result3 = Aquarium::Finders::FinderResult.new :c => [:c1, :c2]
    result123a = (result1 & result2) & result3
    result123b = result1 & (result2 & result3)
    result123a.should be_eql(result123b)
  end    
end


describe "subtraction of finder results", :shared => true do
  it "should return an empty FinderResult if self is substracted from itself." do
    result = Aquarium::Finders::FinderResult.new :b => [:b1, :b2]
    (result - result).should be_empty
  end

  it "should not be associative" do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2], :b => [:b1, :b2], :not_matched => {:c => [:c1, :c2]}
    result2 = Aquarium::Finders::FinderResult.new :a => [:a1]
    result3 = Aquarium::Finders::FinderResult.new :not_matched => {:c => [:c1]}
    result123a = (result1 - result2) - result3
    result123b = result1 - (result2 - result3)
    result123a.should_not be_eql(result123b)
  end    
end

describe Aquarium::Finders::FinderResult, "#minus" do
  it_should_behave_like "subtraction of finder results"
end
describe Aquarium::Finders::FinderResult, "#-" do
  it_should_behave_like "subtraction of finder results"

  it "should support operator-style semantics" do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2], :b => [:b1, :b2], :not_matched => {:c => [:c1, :c2]}
    result2 = Aquarium::Finders::FinderResult.new :b => [:b1]
    result3 = Aquarium::Finders::FinderResult.new :not_matched => {:c => [:c1]}
    result123a = (result1 - result2) - result3
    result123b = result1 - (result2 - result3)
    result123a.should_not be_eql(result123b)
  end    
end


describe Aquarium::Finders::FinderResult, "#.append_matched" do
  it "should not change self, if no arguments are specified." do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2], :b => [:b1, :b2]
    result1.append_matched 
    result1.matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
  end

  it "should return the appended data when used with an empty finder result." do
    result1 = Aquarium::Finders::FinderResult.new
    result1.append_matched :a => [:a1, :a2], :b => [:b1, :b2]
    result1.matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
  end
  
  it "should append the input hash to the corresponding keys and values." do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2], :b => [:b1, :b2]
    result1.append_matched :a => [:a3, :a4], :b => [:b3], :c => [:c1, :c2]
    result1.matched.should == {:a => Set.new([:a1, :a2, :a3, :a4]), :b => Set.new([:b1, :b2, :b3]), :c => Set.new([:c1, :c2])}
  end

  it "should accept single hash values as well as arrays of values." do
    result1 = Aquarium::Finders::FinderResult.new :a => [:a1, :a2], :b => [:b1, :b2]
    result1.append_matched :a => :a3, :b => :b3, :c => :c1
    result1.matched.should == {:a => Set.new([:a1, :a2, :a3]), :b => Set.new([:b1, :b2, :b3]), :c => Set.new([:c1])}
  end
end

describe Aquarium::Finders::FinderResult, "#.append_not_matched" do
  it "should not change self, by default." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:a => [:a1, :a2], :b => [:b1, :b2]}
    result1.append_not_matched
    result1.not_matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
  end

  it "should work with a default (empty) result." do
    result1 = Aquarium::Finders::FinderResult.new
    result1.append_not_matched :a => [:a1, :a2], :b => [:b1, :b2]
    result1.not_matched.should == {:a => Set.new([:a1, :a2]), :b => Set.new([:b1, :b2])}
  end

  it "should append the input hash to the corresponding keys and values." do
    result1 = Aquarium::Finders::FinderResult.new :not_matched => {:a => [:a1, :a2], :b => [:b1, :b2]}
    result1.append_not_matched :a => [:a3, :a4], :b => [:b3], :c => [:c1, :c2]
    result1.not_matched.should == {:a => Set.new([:a1, :a2, :a3, :a4]), :b => Set.new([:b1, :b2, :b3]), :c => Set.new([:c1, :c2])}
  end
end

describe "equality", :shared => true do
  it "should return true for the same object." do
    result = Aquarium::Finders::FinderResult.new
    result.should be_eql(result)
  end

  it "should return true for two default objects." do
    result1 = Aquarium::Finders::FinderResult.new
    result2 = Aquarium::Finders::FinderResult.new
    result1.should be_eql(result2)
  end

  it "should return false for two different objects that are equal and map to the same method." do
    result1 = Aquarium::Finders::FinderResult.new ExampleParentClass.new => :a
    result2 = Aquarium::Finders::FinderResult.new ExampleParentClass.new => :a
    result1.should_not eql(result2)
  end

  it "should return true if a key has a single value that equals the value in a 1-element array for the same key in the other FinderResult." do
    result1 = Aquarium::Finders::FinderResult.new :a => 'a',   :not_matched => {:b => 'b'}
    result2 = Aquarium::Finders::FinderResult.new :a => ['a'], :not_matched => {:b => ['b']}
    result1.should be_eql(result2)
  end

  it "should return false for two objects that are different." do
    result1 = Aquarium::Finders::FinderResult.new :a => 'a'
    result2 = Aquarium::Finders::FinderResult.new :b => 'b'
    result1.should_not eql(result2)
  end
end

describe Aquarium::Finders::FinderResult, "#eql?" do
  it_should_behave_like "equality"
end

describe Aquarium::Finders::FinderResult, "#==" do
  it_should_behave_like "equality"
end
