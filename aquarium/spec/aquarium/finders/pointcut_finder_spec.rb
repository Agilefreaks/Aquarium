require File.dirname(__FILE__) + '/../spec_helper'
require 'aquarium/dsl'
require 'aquarium/finders/pointcut_finder'

module Aquarium
  class PointcutConstantHolder1
    include Aquarium::DSL
    def mc1; end
    POINTCUT1 = Aquarium::Aspects::Pointcut.new :calls_to => :mc1
  end
  class PointcutConstantHolder2
    include Aquarium::DSL
    def mc2; end
    POINTCUT2 = Aquarium::Aspects::Pointcut.new :calls_to => :mc2
  end
  class PointcutClassVariableHolder1
    include Aquarium::DSL
    def mcv1; end
    @@pointcut1 = Aquarium::Aspects::Pointcut.new :calls_to => :mcv1
    def self.pointcut1; @@pointcut1; end
  end
  class OuterPointcutHolder
    class NestedPointcutConstantHolder1
      include Aquarium::DSL
      def m11; end
      POINTCUT11 = Aquarium::Aspects::Pointcut.new :calls_to => :m11
    end
    class NestedPointcutClassVariableHolder1
      include Aquarium::DSL
      def mcv11; end
      @@pointcut11 = Aquarium::Aspects::Pointcut.new :calls_to => :mcv11
      def self.pointcut11; @@pointcut11; end
    end
  end
end

def sort_pc_array pc_array
  pc_array.sort{|x,y| x.object_id <=> y.object_id}
end
def found_pointcuts_should_match found_result_set, expected_found_pc_array, expected_not_found_type_array = []
  found_result_set.matched.size.should == expected_found_pc_array.size
  found_result_set.not_matched.size.should == expected_not_found_type_array.size
  sort_pc_array(found_result_set.found_pointcuts).should eql(expected_found_pc_array)
end

def all_pointcut_classes
  [Aquarium::PointcutConstantHolder1, 
   Aquarium::PointcutConstantHolder2,
   Aquarium::PointcutClassVariableHolder1,  
   Aquarium::OuterPointcutHolder::NestedPointcutConstantHolder1, 
   Aquarium::OuterPointcutHolder::NestedPointcutClassVariableHolder1]
end
def all_pointcuts
  sort_pc_array [Aquarium::PointcutConstantHolder1::POINTCUT1, 
   Aquarium::PointcutConstantHolder2::POINTCUT2,
   Aquarium::PointcutClassVariableHolder1.pointcut1,  
   Aquarium::OuterPointcutHolder::NestedPointcutConstantHolder1::POINTCUT11, 
   Aquarium::OuterPointcutHolder::NestedPointcutClassVariableHolder1.pointcut11]
end
def all_constants_pointcuts
  sort_pc_array [Aquarium::PointcutConstantHolder1::POINTCUT1, 
   Aquarium::PointcutConstantHolder2::POINTCUT2,
   Aquarium::OuterPointcutHolder::NestedPointcutConstantHolder1::POINTCUT11]
end
def all_class_variables_pointcuts
  sort_pc_array [Aquarium::PointcutClassVariableHolder1.pointcut1,  
   Aquarium::OuterPointcutHolder::NestedPointcutClassVariableHolder1.pointcut11]
end

describe Aquarium::Finders::PointcutFinder, "#find with invalid invocation parameters" do
  it "should raise if no options are specified." do
    lambda { Aquarium::Finders::PointcutFinder.new.find}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should raise if no type options are specified." do
    lambda { Aquarium::Finders::PointcutFinder.new.find :matching => :foo}.should raise_error(Aquarium::Utils::InvalidOptions)
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with valid type invocation parameters" do
  it "should accept :types with a single type." do
    lambda { Aquarium::Finders::PointcutFinder.new.find :types => Aquarium::PointcutConstantHolder1, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should accept :types with an array of types." do
    lambda { Aquarium::Finders::PointcutFinder.new.find :types => [Aquarium::PointcutConstantHolder1, Aquarium::PointcutConstantHolder2], :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  it "should accept :types with a regular expression for types." do
    lambda { Aquarium::Finders::PointcutFinder.new.find :types => /Aquarium::PointcutConstantHolder/, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
  end
  Aquarium::Finders::PointcutFinder::CANONICAL_OPTIONS["types"].each do |synonym|
    it "should accept :#{synonym} as a synonym for :types." do
      lambda { Aquarium::Finders::PointcutFinder.new.find synonym.intern => /Aquarium::PointcutConstantHolder/, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with nonexistent types specified" do
  it "should return an empty FinderResult." do
    found = Aquarium::Finders::PointcutFinder.new.find :types => /UndefinedType/
    found.matched.should be_empty
    found.not_matched.keys.should eql([/UndefinedType/])
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with no pointcut name parameter" do
  it "should match all constant and class variable pointcuts in the specified types." do
    found = Aquarium::Finders::PointcutFinder.new.find :types => all_pointcut_classes
    found_pointcuts_should_match found, all_pointcuts
  end
end

variants = {'constant and class variable ' => '', 'constant ' => 'constants_', 'class variable ' => 'class_variables_'}.each do |name, prefix|
  describe Aquarium::Finders::PointcutFinder, "#find with valid #{name}name invocation parameters" do
    it "should accept :#{prefix}matching => :all and match all #{name} pointcuts in the specified types." do
      found = Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => :all, :types => all_pointcut_classes
      found_pointcuts_should_match found, eval("all_#{prefix}pointcuts")
    end
    it "should accept :#{prefix}matching with a single pointcut name." do
      lambda { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => :POINTCUT1, :types => Aquarium::PointcutConstantHolder1, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end
    it "should accept :#{prefix}matching with an array of pointcut names." do
      lambda { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => [:POINTCUT1, :POINTCUT2], :types => Aquarium::PointcutConstantHolder1, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end
    it "should accept :#{prefix}matching with a regular expression for pointcut names." do
      lambda { Aquarium::Finders::PointcutFinder.new.find "#{prefix}matching".intern => /POINTCUT/, :types => Aquarium::PointcutConstantHolder1, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
    end
    Aquarium::Finders::PointcutFinder::CANONICAL_OPTIONS["#{prefix}matching"].each do |synonym|
      it "should accept :#{synonym} as a synonym for :#{prefix}matching." do
        lambda { Aquarium::Finders::PointcutFinder.new.find synonym.intern => /POINTCUT/, :types => Aquarium::PointcutConstantHolder1, :noop => true}.should_not raise_error(Aquarium::Utils::InvalidOptions)
      end
    end
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => single pointcut name" do
  it "should match all constant and class variable pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => :POINTCUT1, :types => all_pointcut_classes
    found_pointcuts_should_match found, [Aquarium::PointcutConstantHolder1::POINTCUT1]
    found = Aquarium::Finders::PointcutFinder.new.find :matching => :pointcut1, :types => all_pointcut_classes
    found_pointcuts_should_match found, [Aquarium::PointcutClassVariableHolder1.pointcut1]
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => single pointcut name" do
  it "should match all constant pointcuts and no class variable pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => :POINTCUT1, :types => all_pointcut_classes
    found_pointcuts_should_match found, [Aquarium::PointcutConstantHolder1::POINTCUT1]
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => :pointcut1, :types => all_pointcut_classes
    found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => single pointcut name" do
  it "should match all class variable pointcuts and no constant pointcuts that match the specified name exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => :POINTCUT1, :types => all_pointcut_classes
    found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => :pointcut1, :types => all_pointcut_classes
    found_pointcuts_should_match found, [Aquarium::PointcutClassVariableHolder1.pointcut1]
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => /pointcut regexps/" do
  it "should match all constant and class variable pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => /POINTCUT(1+|2)/, :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => /pointcut1/, :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => /pointcut regexps/" do
  it "should match all constant pointcuts and no class variable pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => /POINTCUT(1+|2)/, :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => /pointcut1/, :types => all_pointcut_classes
    found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => /pointcut regexps/" do
  it "should match all class variable pointcuts and no constant pointcuts that match the specified regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => /POINTCUT(1+|2)/, :types => all_pointcut_classes
    found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => /pointcut1/, :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => [pointcut names]" do
  it "should match all constant and class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:pointcut1, :pointcut11], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => [pointcut names]" do
  it "should match all constant pointcuts and no class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:pointcut1, :pointcut11], :types => all_pointcut_classes
    found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => [pointcut names]" do
  it "should match all class variable pointcuts and no constant pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:POINTCUT1, :POINTCUT11, :POINTCUT2], :types => all_pointcut_classes
    found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:pointcut1, :pointcut11], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end

describe Aquarium::Finders::PointcutFinder, "#find with :matching => [pointcut names and regular expressions]" do
  it "should match all constant and class variable pointcuts that match the specified names exactly." do
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :matching => [:pointcut1, /cut11$/], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :constants_matching => [pointcut names and regular expressions]" do
  it "should match all constant pointcuts and no class variable pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_constants_pointcuts    
    found = Aquarium::Finders::PointcutFinder.new.find :constants_matching => [:pointcut1, /cut11$/], :types => all_pointcut_classes
    found_pointcuts_should_match found, []
  end
end
describe Aquarium::Finders::PointcutFinder, "#find with :class_variables_matching => [pointcut names and regular expressions]" do
  it "should match all class variable pointcuts and no constant pointcuts that match the specified names and regular expressions." do
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:POINTCUT1, :POINTCUT11, /CUT2/], :types => all_pointcut_classes
    found_pointcuts_should_match found, []
    found = Aquarium::Finders::PointcutFinder.new.find :class_variables_matching => [:pointcut1, /cut11$/], :types => all_pointcut_classes
    found_pointcuts_should_match found, all_class_variables_pointcuts
  end
end

