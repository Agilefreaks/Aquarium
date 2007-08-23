require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/utils/array_utils'
require 'set'

describe Aquarium::Utils::ArrayUtils, "make_array" do
  
  it "should return an empty array if the input is nil." do
    make_array(nil).should == []
  end
  
  it "should return an empty array if an input array contains all nils." do
    make_array([nil, nil]).should == []
  end
  
  it "should return an empty array if an input Set contains all nils." do
    make_array(Set.new([nil, nil])).should == []
  end
  
  it "should return an array with all nils removed from the input array." do
    make_array([nil, 1, 2, nil, 3, 4]).should == [1, 2, 3, 4]
  end

  it "should return an array with all nils removed from the input Set." do
    make_array(Set.new([nil, 1, 2, nil, 3, 4])).should == [1, 2, 3, 4]
  end

  it "should return an 1-element array with an empty element if the input is empty." do
    make_array("").should == [""]
  end

  it "should return an 1-element array with an element that matched the input element." do
    make_array("123").should == ["123"]
  end

  it "should return an input array unchanged if it contains no nil elements." do
    make_array([1,2,"123"]).should == [1,2,"123"]
  end

  it "should return an input Set#to_a if it contains no nil elements." do
    make_array(Set.new([1,2,"123"])).should == [1,2,"123"]
  end

  it "should accept a list of arguments instead of an array or Set." do
    make_array(nil, nil).should == []
    make_array(nil, 1, 2, nil, 3, 4).should == [1, 2, 3, 4]
  end
end
