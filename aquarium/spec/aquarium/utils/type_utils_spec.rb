require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils/type_utils'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_classes'

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

# We don't compare the sizes, because RSpec will add some classes that we don't care about...
def check_descendent_array clazz, expected
  actual = Aquarium::Utils::TypeUtils.descendents(clazz)
  expected.each {|c| actual.should include(c)}
end

describe Aquarium::Utils::TypeUtils, ".descendents called with a class" do
  it "should return the class itself in the result" do
    Aquarium::Utils::TypeUtils.descendents(BaseForDescendents).should include(BaseForDescendents)
  end

  it "should return just the class if it has no descendents" do
    Aquarium::Utils::TypeUtils.descendents(D11ForDescendents).should eql([D11ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(D2ForDescendents).should  eql([D2ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedD11ForDescendents).should  eql([Aquarium::ForDescendents::NestedD11ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedD2ForDescendents).should   eql([Aquarium::ForDescendents::NestedD2ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedD3ForDescendents).should   eql([Aquarium::ForDescendents::NestedD3ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedD4ForDescendents).should   eql([Aquarium::ForDescendents::NestedD4ForDescendents])
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedD31ForDescendents).should  eql([Aquarium::ForDescendents::NestedD31ForDescendents])
  end

  it "should return all classes and their descendents that derive from a class" do
    Aquarium::Utils::TypeUtils.sample_classes.each do |t|
      check_descendent_array t, Aquarium::Utils::TypeUtils.sample_classes_descendents[t]
    end 
  end
end

describe Aquarium::Utils::TypeUtils, ".descendents called with a module" do
  it "should return the module itself in the result" do
    Aquarium::Utils::TypeUtils.descendents(ModuleForDescendents).should include(ModuleForDescendents)
    Aquarium::Utils::TypeUtils.descendents(Aquarium::ForDescendents::NestedModuleForDescendents).should include(Aquarium::ForDescendents::NestedModuleForDescendents)
  end

  it "should return all classes and their descendents that include a module" do
    Aquarium::Utils::TypeUtils.sample_modules.each do |t|
      check_descendent_array t, Aquarium::Utils::TypeUtils.sample_modules_descendents[t]
    end 
  end
  
  it "should return all modules that include a module" do
    Aquarium::Utils::TypeUtils.descendents(ModuleForDescendents).should include(ModuleForDescendents)
    Aquarium::Utils::TypeUtils.descendents(ModuleForDescendents).should include(Aquarium::ForDescendents::Nested2ModuleForDescendents)
  end
end