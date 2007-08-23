require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'aquarium/extensions/symbol'

describe "Symbol#empty?" do
  
  it "should return true for an empty symbol with whitespace" do
    :" \t ".empty?.should be_true
  end
  
  it "should return false for a non-empty symbol" do
    :x.empty?.should be_false
  end
end

describe "Symbol#strip" do
  it "should return equivalent Symbol if there is no leading or trailing whitespace." do
    :a.strip.should == :a
  end

  it "should return new Symbol with removed leading and/or trailing whitespace, when present." do
    :" \ta\t ".strip.should == :a
  end
end

describe "Symbol#<=>" do
  it "should return < 0 if the string representation of the left-hand side symbol is less than the string representation of the right-hand side symbol." do
    (:a <=> :b).should == -1
  end

  it "should return > 0 if the string representation of the left-hand side symbol is greater than the string representation of the right-hand side symbol." do
    (:b <=> :a).should == 1
  end

  it "should return 0 if the string representation of the left-hand side symbol is equal to the string representation of the right-hand side symbol." do
    (:a <=> :a).should == 0
  end
end
