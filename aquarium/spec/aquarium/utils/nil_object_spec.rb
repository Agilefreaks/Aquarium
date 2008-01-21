require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/nil_object'

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
      nil_object.send(method_name.to_sym).include?("Aquarium::Utils::NilObject").should be_true
    end
  end
end
