require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils/set_utils'

describe Aquarium::Utils::SetUtils, "make_set" do
  include Aquarium::Utils::SetUtils

  before :each do
    @empty_set = Set.new
  end
  
  it "should return an empty set if the input is empty." do
    make_set().should == @empty_set
  end
  
  it "should return an empty set if the input is an empty array." do
    make_set([]).should == @empty_set
  end
  
  it "should return an empty set if the input is nil." do
    make_set(nil).should == @empty_set
  end
  
  it "should return an empty set if the input set contains all nils." do
    make_set([nil, nil]).should == @empty_set
  end
  
  it "should return a set with all input nils removed." do
    make_set([nil, 1, 2, nil, 3, 4]).should == Set.new([1, 2, 3, 4])
  end

  it "should return a 1-element set with an empty element if the input is empty." do
    make_set("").should == Set.new([""])
  end

  it "should return a 1-element set with an element that matched the input element." do
    make_set("123").should == Set.new(["123"])
  end

  it "should return an input set unchanged if it contains no nil elements." do
    make_set([1,2,"123"]).should == Set.new([1,2,"123"])
  end

  it "should accept a single argument." do
    make_set(nil).should == @empty_set
    make_set(1).should == Set.new([1])
  end
  
  it "should accept a list of arguments." do
    make_set(nil, nil).should == @empty_set
    make_set(nil, 1, 2, nil, 3, 4).should == Set.new([1, 2, 3, 4])
  end
  
  it "should accept an array" do
    make_set([nil, 1, 2, nil, 3, 4]).should == Set.new([1, 2, 3, 4])
  end
  
  it "should accept a set" do
    make_set(Set.new([nil, 1, 2, nil, 3, 4])).should == Set.new([1, 2, 3, 4])
  end
end

describe Aquarium::Utils::SetUtils, "strip_set_nils" do
  include Aquarium::Utils::SetUtils

  it "should return an empty set if an empty set is specified" do
    strip_set_nils(Set.new([])).should == Set.new([])
  end

  it "should return an empty set if a set of only nil values is specified" do
    strip_set_nils(Set.new([nil, nil])).should == Set.new([])
  end

  it "should return a set will all nil values removed" do
    strip_set_nils(Set.new([nil, :a, nil, :b])).should == Set.new([:a, :b])
  end
end
