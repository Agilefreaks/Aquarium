require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils/type_utils'

describe Aquarium::Utils::TypeUtils, ".is_type?" do
  it "should be true for a class" do
    Aquarium::Utils::TypeUtils.is_type?(String).should be_true
  end

  it "should be true for a Module" do
    Aquarium::Utils::TypeUtils.is_type?(Kernel).should be_true
  end

  it "should be false for an Object" do
    Aquarium::Utils::TypeUtils.is_type?("Object").should be_false
  end
end