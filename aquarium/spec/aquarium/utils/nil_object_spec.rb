require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/spec_example_types'
require 'aquarium/utils/nil_object'

describe Aquarium::Utils::NilObject, "#eql?" do
  it "should return true when called with any other NilObject" do
    nil_object1 = Aquarium::Utils::NilObject.new
    nil_object2 = Aquarium::Utils::NilObject.new
    nil_object1.should  eql(nil_object1)
    nil_object1.should  eql(nil_object2)
    nil_object2.should  eql(nil_object1)
    nil_object1.eql?(nil_object1).should  be_true
    nil_object1.eql?(nil_object2).should  be_true
    nil_object2.eql?(nil_object1).should  be_true
  end
  
  it "should return false when called with any other object" do
    nil_object = Aquarium::Utils::NilObject.new
    nil_object.not_to eql(nil)
    nil_object.not_to eql("nil_object")
    nil_object.eql?(nil).should  be_false
    nil_object.eql?("nil_object").should  be_false
  end
end
  
describe Aquarium::Utils::NilObject, " (when a message is sent to it)" do
  it "should return itself, by default, for methods not defined for Object" do
    nil_object = Aquarium::Utils::NilObject.new
    %w[a b foo].each do |method_name|
      nil_object.send(method_name.to_sym).should == nil_object
    end
  end
  
  it "should invoke Object's methods, when defined" do
    nil_object = Aquarium::Utils::NilObject.new
    %w[to_s inspect].each do |method_name|
      nil_object.send(method_name.to_sym).include?("Aquarium::Utils::NilObject").should  be_true
    end
  end
end
