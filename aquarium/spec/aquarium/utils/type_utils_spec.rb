require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/utils/type_utils'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_classes'
require File.dirname(__FILE__) + '/../utils/type_utils_sample_nested_types'

include Aquarium::Utils

describe TypeUtils, ".is_type?" do
  it "should be true for a class" do
    TypeUtils.is_type?(String).should be_true
  end

  it "should be true for a Module" do
    TypeUtils.is_type?(Kernel).should be_true
  end

  it "should be false for an Object" do
    TypeUtils.is_type?("Object").should be_false
  end
end

# We don't compare the sizes, because RSpec will add some classes that we don't care about...
def check_descendent_array clazz, expected
  actual = TypeUtils.descendents(clazz)
  expected.each {|c| actual.should include(c)}
end

describe TypeUtils, ".descendents called with a class" do
  it "should return the class itself in the result" do
    TypeUtils.descendents(BaseForDescendents).should include(BaseForDescendents)
  end

  it "should return just the class if it has no descendents" do
    TypeUtils.descendents(D11ForDescendents).should eql([D11ForDescendents])
    TypeUtils.descendents(D2ForDescendents).should  eql([D2ForDescendents])
    TypeUtils.descendents(Aquarium::ForDescendents::NestedD11ForDescendents).should  eql([Aquarium::ForDescendents::NestedD11ForDescendents])
    TypeUtils.descendents(Aquarium::ForDescendents::NestedD2ForDescendents).should   eql([Aquarium::ForDescendents::NestedD2ForDescendents])
    TypeUtils.descendents(Aquarium::ForDescendents::NestedD3ForDescendents).should   eql([Aquarium::ForDescendents::NestedD3ForDescendents])
    TypeUtils.descendents(Aquarium::ForDescendents::NestedD4ForDescendents).should   eql([Aquarium::ForDescendents::NestedD4ForDescendents])
    TypeUtils.descendents(Aquarium::ForDescendents::NestedD31ForDescendents).should  eql([Aquarium::ForDescendents::NestedD31ForDescendents])
  end

  it "should return all classes and their descendents that derive from a class" do
    TypeUtils.sample_classes.each do |t|
      check_descendent_array t, TypeUtils.sample_classes_descendents[t]
    end 
  end
end

describe TypeUtils, ".descendents called with a module" do
  it "should return the module itself in the result" do
    TypeUtils.descendents(ModuleForDescendents).should include(ModuleForDescendents)
    TypeUtils.descendents(Aquarium::ForDescendents::NestedModuleForDescendents).should include(Aquarium::ForDescendents::NestedModuleForDescendents)
  end

  it "should return all classes and their descendents that include a module" do
    TypeUtils.sample_modules.each do |t|
      check_descendent_array t, TypeUtils.sample_modules_descendents[t]
    end 
  end
  
  it "should return all modules that include a module" do
    TypeUtils.descendents(ModuleForDescendents).should include(ModuleForDescendents)
    TypeUtils.descendents(ModuleForDescendents).should include(Aquarium::ForDescendents::Nested2ModuleForDescendents)
  end
end

module FakeJRubyWrapperModule
  %w[ancestors constants const_get].each do |method_name|
    module_eval(<<-EOF, __FILE__, __LINE__)
      def self.__#{method_name}__(*args)
        self.#{method_name}(*args)
      end
    EOF
  end
end
class FakeJRubyWrapperClass
  include FakeJRubyWrapperModule
end

# See the separate JRuby spec suite for exhaustive tests of JRuby support. This example really exists solely to ensure 100% coverage.
describe TypeUtils, ".descendents applied to JRuby-wrapped Java classes" do
  it "should properly determine descendents" do
    TypeUtils.descendents(FakeJRubyWrapperModule).should include(FakeJRubyWrapperClass)
  end
end

describe TypeUtils, ".nested called with a type" do
  it "should return the type itself in the result" do
    Aquarium::NestedTestTypes.nested_in_NestedTestTypes.keys.each do |t|
      TypeUtils.nested(t).should include(t)
    end
  end

  it "should return all the modules and classes nested under the type, inclusive" do
    Aquarium::NestedTestTypes.nested_in_NestedTestTypes.keys.each do |t|
      actual_types = TypeUtils.nested(t)
      actual_types.sort{|x,y| x.name <=> y.name}.should == Aquarium::NestedTestTypes.nested_in_NestedTestTypes[t].sort{|x,y| x.name <=> y.name}
    end
  end
end

